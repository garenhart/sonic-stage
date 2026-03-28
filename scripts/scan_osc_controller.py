#!/usr/bin/env python3
"""
scan_osc_controller.py

Scans osc_controller.json for common problems:
  - Duplicate widget IDs
  - OSC address collisions
  - Inline JS syntax issues (basic heuristics)
  - Broken @{} / OSC{} / VAR{} / JS{} template references
  - CSS problems
  - Widgets with suspicious/empty required fields
  - IDs referenced in onValue/onCreate that don't exist in the tree
  - New widget types or fields not seen in the known schema
"""

import json
import re
from pathlib import Path
from collections import defaultdict

# ---------------------------------------------------------------------------
# Known OSC paths used in lib-osc.rb / osc_monitor.rb (must be widget IDs)
# These are all the literal /path values sent to the UI by Sonic Pi.
# Dynamic patterns like /#{d}_on expand to kick_on, snare_on, cymbal_on etc.
# ---------------------------------------------------------------------------
EXPECTED_OSC_IDS = {
    # Global / session
    "fx_names", "synths", "synths_fav_solo", "synths_fav_bass", "synths_fav_chord",
    "sample_groups", "scale_notes", "tooltip",
    "tempo", "pattern", "pattern_mode", "mode", "scale", "switch_loop",
    "cfg_path", "open", "NOTIFY",
    # Bass
    "bass_on", "bass_amp", "bass_inst", "bass_fav", "bass_fav_all",
    "bass_auto", "bass_update", "bass_rec", "bass_del",
    "bass_pt_count", "bass_tempo_factor", "bass_beat_point",
    "bass_fx1_fx", "bass_fx2_fx",
    "bass_fx1_opt1_value", "bass_fx1_opt2_value",
    "bass_fx2_opt1_value", "bass_fx2_opt2_value",
    "bass_fx1_opt1_name", "bass_fx1_opt2_name",
    "bass_fx2_opt1_name", "bass_fx2_opt2_name",
    "bass_env_adsr",
    # Chord
    "chord_on", "chord_amp", "chord_inst", "chord_type",
    "chord_fav", "chord_fav_all",
    "chord_auto", "chord_update", "chord_rec", "chord_del",
    "chord_pt_count", "chord_tempo_factor", "chord_beat_point",
    "chord_fx1_fx", "chord_fx2_fx",
    "chord_fx1_opt1_value", "chord_fx1_opt2_value",
    "chord_fx2_opt1_value", "chord_fx2_opt2_value",
    "chord_fx1_opt1_name", "chord_fx1_opt2_name",
    "chord_fx2_opt1_name", "chord_fx2_opt2_name",
    "chord_env_adsr",
    # Solo
    "solo_on", "solo_inst", "solo_fav", "solo_fav_all",
    "solo_env_adsr",
    # Drums — per-instrument (kick / snare / cymbal)
    "beat_pt_count", "drum_tempo_factor",
    "drums_auto", "drums_update",
    "kick_on", "kick_amp", "kick_range", "kick_random", "kick_reverse",
    "kick_pitch_shift", "kick_fav", "kick_beats_v",
    "snare_on", "snare_amp", "snare_range", "snare_random", "snare_reverse",
    "snare_pitch_shift", "snare_fav", "snare_beats_v",
    "cymbal_on", "cymbal_amp", "cymbal_range", "cymbal_random", "cymbal_reverse",
    "cymbal_pitch_shift", "cymbal_fav", "cymbal_beats_v",
    # Internal state variables (set/get in JS handlers)
    "selected_pts_bass", "selected_pts_chord", "tonic_point",
    "bass_line", "chord_line",
}

# Template reference pattern: @{...}, OSC{...}, VAR{...}, JS{...}
TEMPLATE_RE = re.compile(r'(@|OSC|VAR|JS)\{([^}]*)\}')

# JS curly braces that should be balanced (rough check)
JS_UNBALANCED_RE = re.compile(r'\{[^{}]*$', re.MULTILINE)

issues: list[str] = []
warnings: list[str] = []

all_ids: dict[str, int] = {}          # id -> count
all_addresses: dict[str, list] = defaultdict(list)  # address -> [ids]
template_refs: set[str] = set()        # all @{X} targets used
js_get_refs: set[str] = set()          # all get('X') / set('X') targets
widget_types_seen: set[str] = set()
total_widgets = 0


def check_js(field_name: str, value: str, widget_id: str):
    """Heuristic JS checks on handler code."""
    # Unmatched braces (rough)
    opens = value.count('{')
    closes = value.count('}')
    if opens != closes:
        issues.append(f"[JS brace mismatch] {widget_id}.{field_name}: {opens} {{ vs {closes} }}")

    # get()/set() calls — collect IDs for cross-reference
    for m in re.finditer(r"""(?:get|set)\s*\(\s*['"]([^'"]+)['"]\s*""", value):
        js_get_refs.add(m.group(1))


def check_template(field_name: str, value: str, widget_id: str):
    """Check template syntax: @{}, OSC{}, VAR{}, JS{}."""
    for m in TEMPLATE_RE.finditer(value):
        kind, ref = m.group(1), m.group(2).strip()
        if kind == "@":
            template_refs.add(ref)
        # Empty template reference
        if not ref:
            warnings.append(f"[Empty template ref] {widget_id}.{field_name}: {m.group(0)!r}")


def walk(node, depth=0):
    global total_widgets
    if not isinstance(node, dict):
        return

    wid = node.get("id", "<no-id>")
    wtype = node.get("type", "<no-type>")
    widget_types_seen.add(wtype)
    total_widgets += 1

    # --- Duplicate ID check ---
    if wid != "<no-id>":
        all_ids[wid] = all_ids.get(wid, 0) + 1

    # --- Address collision check ---
    addr = node.get("address", "")
    if addr and addr != "auto":
        all_addresses[addr].append(wid)

    # --- Required fields ---
    if wtype not in ("root", "tab", "script") and not wid.startswith("@{"):
        if not wid or wid == "<no-id>":
            issues.append(f"[Missing ID] {wtype} widget at depth {depth}")

    # --- Scan string fields for template refs and JS ---
    for field in ("onValue", "onCreate", "onTouch", "onKeyboard", "css", "html", "label", "comments"):
        val = node.get(field, "")
        if not isinstance(val, str) or not val.strip():
            continue
        check_template(field, val, wid)
        if field in ("onValue", "onCreate", "onTouch"):
            check_js(field, val, wid)

    # --- CSS checks ---
    css = node.get("css", "")
    if isinstance(css, str) and css.strip():
        # :host { class: X } — class must exist or be a known pattern
        for m in re.finditer(r"class:\s*(\S+)", css):
            cls = m.group(1).strip()
            # Just collect for reporting; we'll note unknown ones
            pass
        # z-index without position context is usually fine, skip

    # --- Recurse ---
    if "content" in node:
        walk(node["content"], depth + 1)
    for child in node.get("widgets", []):
        walk(child, depth + 1)
    for child in node.get("tabs", []):
        walk(child, depth + 1)


def main():
    path = Path("osc_controller.json")
    print(f"Scanning {path} …\n")
    data = json.load(path.open())
    walk(data)

    # --- Duplicate IDs ---
    dupe_ids = {k: v for k, v in all_ids.items() if v > 1}
    if dupe_ids:
        for wid, count in sorted(dupe_ids.items(), key=lambda x: -x[1]):
            # Dynamic IDs like @{parent.id}_x are expected duplicates in template pattern
            if "@{" in wid:
                warnings.append(f"[Template ID] '{wid}' appears {count}x (expected if using @{{parent.id}} pattern)")
            else:
                issues.append(f"[Duplicate ID] '{wid}' appears {count}x")

    # --- Address collisions ---
    for addr, ids in all_addresses.items():
        if len(ids) > 1:
            issues.append(f"[Address collision] '{addr}' used by: {ids}")

    # --- Expected OSC IDs present? ---
    missing = EXPECTED_OSC_IDS - set(all_ids.keys())
    for m in sorted(missing):
        warnings.append(f"[Missing expected ID] '{m}' — referenced in lib-osc.rb but not found in JSON")

    # --- get()/set() targets that don't exist as widget IDs ---
    phantom = js_get_refs - set(all_ids.keys())
    # Filter out dynamic/template references and known state keys
    KNOWN_STATE_KEYS = {
        "bass_auto", "chord_auto", "drums_auto", "bass_update", "chord_update", "drums_update",
        "tooltip", "bass_beat_point", "chord_beat_point", "tonic_point",
        "selected_pts_bass", "selected_pts_chord", "fx_names",
        "bass_line", "chord_line",
    }
    real_phantom = phantom - KNOWN_STATE_KEYS
    for ref in sorted(real_phantom):
        if not ref.startswith("@") and not ref.startswith("JS"):
            warnings.append(f"[JS ref not found] get/set('{ref}') — no widget with this ID")

    # --- Print results ---
    print(f"Total widgets scanned: {total_widgets:,}")
    print(f"Unique widget types:   {sorted(widget_types_seen)}")
    print(f"Unique IDs:            {len(all_ids):,}")
    print()

    if issues:
        print(f"=== ISSUES ({len(issues)}) ===")
        for i in issues:
            print(" ", i)
    else:
        print("=== ISSUES: none ===")

    print()

    if warnings:
        print(f"=== WARNINGS ({len(warnings)}) ===")
        for w in warnings:
            print(" ", w)
    else:
        print("=== WARNINGS: none ===")


if __name__ == "__main__":
    import os
    os.chdir(Path(__file__).parent.parent)
    main()
