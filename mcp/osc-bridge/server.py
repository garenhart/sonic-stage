#!/usr/bin/env python3
"""
Sonic Stage OSC bridge — a zero-dependency MCP (stdio) server.

It lets an MCP client (Claude Code) drive a running Sonic Stage session by
*impersonating Open Stage Control*: it binds the UDP socket to the controller
port (default 7777) and sends OSC to Sonic Pi (default 4560). Sonic Pi's
:osc_monitor loop only reacts to messages whose source port is the controller
port, which is why we bind 7777 rather than an ephemeral port.

Because the bridge owns port 7777, run it with Open Stage Control CLOSED
(headless mode). Sonic Pi also emits OSC back to 7777 (/current_beat, /NOTIFY,
dropdown fills); the bridge buffers those so `read_messages` can observe them.

Pure standard library only: works on the stock macOS python3 (3.9+), no pip
install, no Node. MCP stdio framing is newline-delimited JSON-RPC 2.0. OSC 1.0
encoding/decoding is implemented inline.

Config via env vars:
  SS_SEND_HOST (default 127.0.0.1)  Sonic Pi host
  SS_SEND_PORT (default 4560)       Sonic Pi OSC listen port
  SS_BIND_HOST (default 127.0.0.1)  local bind host
  SS_BIND_PORT (default 7777)       local bind port = controller port to spoof
"""

import json
import os
import socket
import struct
import sys
import threading
import time
from collections import deque

# ----------------------------------------------------------------------------
# Config
# ----------------------------------------------------------------------------
SEND_HOST = os.environ.get("SS_SEND_HOST", "127.0.0.1")
SEND_PORT = int(os.environ.get("SS_SEND_PORT", "4560"))
BIND_HOST = os.environ.get("SS_BIND_HOST", "127.0.0.1")
BIND_PORT = int(os.environ.get("SS_BIND_PORT", "7777"))

PROTOCOL_VERSION_DEFAULT = "2025-06-18"
SERVER_NAME = "sonic-stage-osc-bridge"
SERVER_VERSION = "0.1.0"
RECV_BUFFER_MAX = 500


def log(*a):
    """Logs go to stderr; stdout is reserved for the JSON-RPC stream."""
    print("[osc-bridge]", *a, file=sys.stderr, flush=True)


# ----------------------------------------------------------------------------
# OSC 1.0 encode / decode (no dependencies)
# ----------------------------------------------------------------------------
def _pad(b: bytes) -> bytes:
    """Pad a byte string with NULs to a multiple of 4."""
    return b + b"\x00" * (4 - (len(b) % 4) if len(b) % 4 else 0)


def _osc_string(s: str) -> bytes:
    return _pad(s.encode("utf-8") + b"\x00")


def osc_encode(address: str, args) -> bytes:
    """Encode an OSC message. Arg python types map to OSC types:
    bool->i(1/0), int->i, float->f, str->s. None is skipped."""
    typetags = ","
    body = b""
    for a in args:
        if isinstance(a, bool):
            typetags += "i"
            body += struct.pack(">i", 1 if a else 0)
        elif isinstance(a, int):
            typetags += "i"
            body += struct.pack(">i", a)
        elif isinstance(a, float):
            typetags += "f"
            body += struct.pack(">f", a)
        elif isinstance(a, str):
            typetags += "s"
            body += _osc_string(a)
        else:
            # fall back to string repr rather than raising on the audio path
            typetags += "s"
            body += _osc_string(str(a))
    return _osc_string(address) + _osc_string(typetags) + body


def _read_osc_string(data: bytes, i: int):
    end = data.index(b"\x00", i)
    s = data[i:end].decode("utf-8", "replace")
    # advance past the string and its NUL padding to next 4-byte boundary
    j = end + 1
    if (j - i) % 4:
        j += 4 - ((j - i) % 4)
    return s, j


def osc_decode(data: bytes):
    """Decode a single OSC message into (address, [args]). Bundles and
    unsupported types are handled defensively (best effort)."""
    if data[:1] == b"#":  # bundle (#bundle) — decode first contained message
        # 8-byte tag + 8-byte timetag, then size-prefixed elements
        i = 16
        if len(data) >= i + 4:
            (size,) = struct.unpack(">i", data[i:i + 4])
            return osc_decode(data[i + 4:i + 4 + size])
        return "#bundle", []
    address, i = _read_osc_string(data, 0)
    if i >= len(data) or data[i:i + 1] != b",":
        return address, []
    typetags, i = _read_osc_string(data, i)
    args = []
    for t in typetags[1:]:
        if t == "i":
            args.append(struct.unpack(">i", data[i:i + 4])[0]); i += 4
        elif t == "f":
            args.append(struct.unpack(">f", data[i:i + 4])[0]); i += 4
        elif t == "d":
            args.append(struct.unpack(">d", data[i:i + 8])[0]); i += 8
        elif t == "s" or t == "S":
            s, i = _read_osc_string(data, i); args.append(s)
        elif t == "T":
            args.append(True)
        elif t == "F":
            args.append(False)
        elif t == "N":
            args.append(None)
        elif t == "b":
            (n,) = struct.unpack(">i", data[i:i + 4]); i += 4
            args.append(data[i:i + n]); i += n
            if n % 4:
                i += 4 - (n % 4)
        else:
            break  # unknown type — stop rather than misalign
    return address, args


# ----------------------------------------------------------------------------
# UDP transport: one socket bound to BIND_PORT, sends to SEND_PORT
# ----------------------------------------------------------------------------
class OscTransport:
    def __init__(self):
        self.sock = None
        self.bind_error = None
        self.recv = deque(maxlen=RECV_BUFFER_MAX)
        self.lock = threading.Lock()
        self.sent_count = 0
        self.recv_count = 0
        self._open()

    def _open(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind((BIND_HOST, BIND_PORT))
            self.sock = s
            t = threading.Thread(target=self._recv_loop, daemon=True)
            t.start()
            log("bound %s:%d, sending to %s:%d" % (BIND_HOST, BIND_PORT, SEND_HOST, SEND_PORT))
        except OSError as e:
            self.bind_error = str(e)
            log("BIND FAILED on %s:%d — %s. Is Open Stage Control still running?"
                % (BIND_HOST, BIND_PORT, e))

    def _recv_loop(self):
        while True:
            try:
                data, addr = self.sock.recvfrom(65535)
            except OSError:
                break
            try:
                address, args = osc_decode(data)
            except Exception as e:  # never let a malformed packet kill the loop
                address, args = "<decode-error>", [repr(e)]
            with self.lock:
                self.recv.append({"t": time.time(), "address": address,
                                  "args": _jsonable(args), "from": "%s:%d" % addr})
                self.recv_count += 1

    def send(self, address: str, args):
        if self.sock is None:
            raise RuntimeError(
                "OSC socket not bound (%s). Bridge needs port %d free — close "
                "Open Stage Control or set SS_BIND_PORT." % (self.bind_error, BIND_PORT))
        self.sock.sendto(osc_encode(address, args), (SEND_HOST, SEND_PORT))
        self.sent_count += 1

    def read(self, address_filter=None, limit=None, clear=True):
        with self.lock:
            items = list(self.recv)
            if clear:
                self.recv.clear()
        if address_filter:
            items = [m for m in items if address_filter in m["address"]]
        if limit:
            items = items[-int(limit):]
        return items


def _jsonable(args):
    out = []
    for a in args:
        out.append(a.hex() if isinstance(a, (bytes, bytearray)) else a)
    return out


OSC = None  # set in main()


# ----------------------------------------------------------------------------
# Tool implementations — each returns a short human-readable string
# ----------------------------------------------------------------------------
DRUMS = ("kick", "snare", "cymbal")
TOGGLEABLE = ("solo", "bass", "chord", "kick", "snare", "cymbal")
AMPABLE = ("solo", "bass", "chord", "kick", "snare", "cymbal")
INSTABLE = ("solo", "bass", "chord", "kick", "snare", "cymbal")


def _coerce_arg(a):
    # JSON gives us bool/int/float/str already; keep as-is. Numbers that are
    # whole floats stay float here, which is fine for Sonic Pi handlers.
    return a


def tool_osc_send(p):
    address = p["address"]
    if not address.startswith("/"):
        address = "/" + address
    args = [_coerce_arg(a) for a in p.get("args", [])]
    OSC.send(address, args)
    return "sent %s %r" % (address, args)


def tool_set_tempo(p):
    bpm = int(p["bpm"])
    OSC.send("/tempo", [bpm])
    return "tempo -> %d bpm" % bpm


def tool_toggle(p):
    target = p["target"]
    if target not in TOGGLEABLE:
        raise ValueError("target must be one of %s" % (TOGGLEABLE,))
    on = 1 if p["on"] else 0
    OSC.send("/%s_on" % target, [on])
    return "%s_on -> %d" % (target, on)


def tool_set_amp(p):
    target = p["target"]
    if target not in AMPABLE:
        raise ValueError("target must be one of %s" % (AMPABLE,))
    value = float(p["value"])
    OSC.send("/%s_amp" % target, [value])
    return "%s_amp -> %s" % (target, value)


def tool_set_instrument(p):
    target = p["target"]
    if target not in INSTABLE:
        raise ValueError("target must be one of %s" % (INSTABLE,))
    name = str(p["name"])
    # drums use /<d>_inst with a sample name; bass/chord/solo use /<t>_inst synth
    OSC.send("/%s_inst" % target, [name])
    return "%s_inst -> %s" % (target, name)


def tool_set_beats(p):
    drum = p["drum"]
    if drum not in DRUMS:
        raise ValueError("drum must be one of %s" % (DRUMS,))
    pattern = str(p["pattern"]).strip()
    if any(c not in "01" for c in pattern):
        raise ValueError("pattern must be a string of '0'/'1', e.g. '1000100010001000'")
    # The UI sends one message per step: /<drum>_beats/<index> <bit>
    for i, c in enumerate(pattern):
        OSC.send("/%s_beats/%d" % (drum, i), [int(c)])
    return "%s beats -> %s (%d steps)" % (drum, pattern, len(pattern))


def tool_load_config(p):
    path = str(p["path"])
    OSC.send("/open", [path])
    return "requested config load: %s" % path


def tool_read_messages(p):
    items = OSC.read(address_filter=p.get("address_filter"),
                     limit=p.get("limit"),
                     clear=p.get("clear", True))
    if not items:
        return "no messages buffered (sent=%d, received=%d total)" % (
            OSC.sent_count, OSC.recv_count)
    lines = []
    for m in items:
        ago = time.time() - m["t"]
        lines.append("%5.1fs ago  %s %s" % (ago, m["address"], m["args"]))
    return "%d message(s):\n%s" % (len(items), "\n".join(lines))


def tool_status(p):
    return json.dumps({
        "bound": OSC.sock is not None,
        "bind": "%s:%d" % (BIND_HOST, BIND_PORT),
        "send_to": "%s:%d" % (SEND_HOST, SEND_PORT),
        "bind_error": OSC.bind_error,
        "sent_count": OSC.sent_count,
        "recv_count": OSC.recv_count,
        "buffered": len(OSC.recv),
    }, indent=2)


# ----------------------------------------------------------------------------
# Tool registry (name -> (handler, description, inputSchema))
# ----------------------------------------------------------------------------
def _schema(props, required=()):
    return {"type": "object", "properties": props, "required": list(required),
            "additionalProperties": False}


TOOLS = {
    "osc_send": (tool_osc_send,
        "Send a raw OSC message to Sonic Pi (escape hatch for any controller path). "
        "Args are sent in order; JSON bools become int 1/0.",
        _schema({"address": {"type": "string", "description": "OSC path, e.g. /tempo or /kick_beats/3"},
                 "args": {"type": "array", "items": {"type": ["number", "string", "boolean"]},
                          "description": "ordered OSC arguments"}}, ["address"])),
    "set_tempo": (tool_set_tempo, "Set the global tempo in BPM (sends /tempo).",
        _schema({"bpm": {"type": "integer", "minimum": 1, "maximum": 400}}, ["bpm"])),
    "toggle": (tool_toggle, "Turn an instrument on/off (sends /<target>_on).",
        _schema({"target": {"type": "string", "enum": list(TOGGLEABLE)},
                 "on": {"type": "boolean"}}, ["target", "on"])),
    "set_amp": (tool_set_amp, "Set an instrument amplitude/volume (sends /<target>_amp).",
        _schema({"target": {"type": "string", "enum": list(AMPABLE)},
                 "value": {"type": "number", "minimum": 0}}, ["target", "value"])),
    "set_instrument": (tool_set_instrument,
        "Select the synth (bass/chord/solo) or sample (kick/snare/cymbal) by name "
        "(sends /<target>_inst).",
        _schema({"target": {"type": "string", "enum": list(INSTABLE)},
                 "name": {"type": "string"}}, ["target", "name"])),
    "set_beats": (tool_set_beats,
        "Set a drum's full step pattern from a '0'/'1' string (one OSC msg per step).",
        _schema({"drum": {"type": "string", "enum": list(DRUMS)},
                 "pattern": {"type": "string", "description": "e.g. '1000100010001000'"}},
                ["drum", "pattern"])),
    "load_config": (tool_load_config,
        "Load a Sonic Stage config by absolute JSON path (sends /open).",
        _schema({"path": {"type": "string", "description": "absolute path to a config .json"}}, ["path"])),
    "read_messages": (tool_read_messages,
        "Read OSC messages Sonic Stage has emitted back to the controller port "
        "(e.g. /current_beat, /NOTIFY). Clears the buffer by default.",
        _schema({"address_filter": {"type": "string", "description": "substring match on address"},
                 "limit": {"type": "integer"},
                 "clear": {"type": "boolean", "description": "default true"}})),
    "status": (tool_status, "Report bridge socket binding and send/recv counts.",
        _schema({})),
}


# ----------------------------------------------------------------------------
# Minimal MCP stdio JSON-RPC loop
# ----------------------------------------------------------------------------
def _result(id_, result):
    return {"jsonrpc": "2.0", "id": id_, "result": result}


def _error(id_, code, message):
    return {"jsonrpc": "2.0", "id": id_, "error": {"code": code, "message": message}}


def handle_request(msg):
    method = msg.get("method")
    id_ = msg.get("id")
    params = msg.get("params") or {}

    if method == "initialize":
        proto = params.get("protocolVersion", PROTOCOL_VERSION_DEFAULT)
        return _result(id_, {
            "protocolVersion": proto,
            "capabilities": {"tools": {}},
            "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION},
        })

    if method == "ping":
        return _result(id_, {})

    if method == "tools/list":
        tools = [{"name": n, "description": d, "inputSchema": s}
                 for n, (_, d, s) in TOOLS.items()]
        return _result(id_, {"tools": tools})

    if method == "tools/call":
        name = params.get("name")
        args = params.get("arguments") or {}
        entry = TOOLS.get(name)
        if entry is None:
            return _error(id_, -32602, "unknown tool: %s" % name)
        handler = entry[0]
        try:
            text = handler(args)
            return _result(id_, {"content": [{"type": "text", "text": text}]})
        except Exception as e:  # surface tool errors to the model, don't crash
            return _result(id_, {"content": [{"type": "text", "text": "ERROR: %s" % e}],
                                 "isError": True})

    if id_ is None:
        return None  # a notification we don't handle (e.g. notifications/initialized)
    return _error(id_, -32601, "method not found: %s" % method)


def main():
    global OSC
    OSC = OscTransport()
    log("ready — tools: %s" % ", ".join(TOOLS))
    out = sys.stdout
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError as e:
            log("bad json: %s" % e)
            continue
        try:
            resp = handle_request(msg)
        except Exception as e:
            resp = _error(msg.get("id"), -32603, "internal error: %s" % e)
        if resp is not None:
            out.write(json.dumps(resp) + "\n")
            out.flush()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
