# Sonic Stage OSC bridge (MCP server)

A zero-dependency MCP server that lets Claude Code drive a **running** Sonic
Stage session by impersonating Open Stage Control over OSC.

## How it works

Sonic Pi's `:osc_monitor` loop in [`osc_monitor.rb`](../../osc_monitor.rb) syncs on
`"/osc:127.0.0.1:7777/**"` — it only reacts to OSC whose **source port is 7777**
(the controller port, `:ctrl_port`). So the bridge:

- binds its UDP socket to **127.0.0.1:7777** (the port Open Stage Control normally uses),
- **sends** OSC to Sonic Pi on **127.0.0.1:4560** (Sonic Pi's listen port), and
- **receives** the OSC Sonic Pi emits back to 7777 (`/current_beat`, `/NOTIFY`,
  dropdown fills) into a buffer you can read with `read_messages`.

It speaks the same paths the UI sends (see [`lib/lib-mon.rb`](../../lib/lib-mon.rb)):
`/tempo`, `/bass_on`, `/solo_amp`, `/kick_beats/<i>`, `/open`, etc. No auth token
is required (unlike Sonic Pi's `/run-code`), and because it goes through the real
controller code path, changes mutate the live `cfg` your loops use.

## Run mode: headless (UI closed)

Only one process can own port 7777. **Close Open Stage Control** before using the
bridge — they cannot both bind 7777. Sonic Pi itself stays running (load
`sonic-stage.rb` as usual). If you want to drive the system *alongside* a live UI
instead, that needs a small second-listener change in `osc_monitor.rb` — not done
here.

If the bind fails, `status`/tool calls will say so; that almost always means Open
Stage Control is still running.

## Tools

| Tool | What it sends |
|------|---------------|
| `set_tempo {bpm}` | `/tempo <bpm>` |
| `toggle {target, on}` | `/<target>_on <1\|0>` (solo/bass/chord/kick/snare/cymbal) |
| `set_amp {target, value}` | `/<target>_amp <float>` |
| `set_instrument {target, name}` | `/<target>_inst <name>` (synth or sample) |
| `set_beats {drum, pattern}` | `/<drum>_beats/<i> <bit>` per step, e.g. `"1000100010001000"` |
| `load_config {path}` | `/open <abs path>` — loads a whole config |
| `osc_send {address, args[]}` | raw escape hatch for any path |
| `read_messages {address_filter?, limit?, clear?}` | reads OSC emitted back from Sonic Pi |
| `status` | socket binding + sent/recv counts |

## Configuration

Override via env vars (set in [`.mcp.json`](../../.mcp.json)):

- `SS_SEND_HOST` / `SS_SEND_PORT` — Sonic Pi (default `127.0.0.1` / `4560`)
- `SS_BIND_HOST` / `SS_BIND_PORT` — local bind = controller port to spoof (default `127.0.0.1` / `7777`)

## Manual smoke test (no MCP client)

```bash
# list tools
printf '%s\n%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
  | python3 mcp/osc-bridge/server.py
```

## Requirements

Stock `python3` (3.9+). No pip install, no Node.
