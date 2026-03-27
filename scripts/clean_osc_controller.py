#!/usr/bin/env python3
"""
clean_osc_controller.py

Strips Open Stage Control JSON properties that match OSC schema defaults,
removing verbosity without changing any widget behaviour.

Usage:
    python3 scripts/clean_osc_controller.py
Outputs:
    osc_controller.clean.json  (original is untouched)
    prints a summary of lines before/after and properties removed
"""

import json
import copy
from pathlib import Path

# ---------------------------------------------------------------------------
# Default values to strip — only removed when the value exactly matches.
# Keys with value None are treated as "remove when equal to any of the listed
# sentinel values" (both the string "false" and boolean False for expand).
# ---------------------------------------------------------------------------

# Properties whose default is a plain string/number/bool — strip when equal.
UNIVERSAL_DEFAULTS = {
    # empties
    "comments":  "",
    "html":      "",
    "linkId":    "",
    "preArgs":   "",
    "typeTags":  "",
    "target":    "",
    "gridTemplate": "",
    # bool false
    "ignoreDefaults": False,
    "bypass":    False,
    "lock":      False,
    "traversing": False,
    # bool true
    "visible":   True,
    "interaction": True,
    "contain":   True,
    "scroll":    True,
    "innerPadding": True,
    # numeric / string defaults
    "decimals":  2,
    "default":   "",
    "value":     "",
    "layout":    "default",
    "justify":   "start",
    "tabsPosition": "top",
    # OSC address
    "address":   "auto",
    # color / visual "auto" defaults
    "colorText":    "auto",
    "colorWidget":  "auto",
    "colorStroke":  "auto",
    "colorFill":    "auto",
    "alphaStroke":  "auto",
    "alphaFillOff": "auto",
    "alphaFillOn":  "auto",
    "lineWidth":    "auto",
    "borderRadius": "auto",
    # positional defaults
    "top":    "auto",
    "left":   "auto",
    "width":  "auto",
    "height": "auto",
}

# "expand" appears as both False (bool) and "false" (string) — treat both as default.
EXPAND_DEFAULTS = {False, "false"}

# Empty-string event handlers — strip only when empty.
EMPTY_HANDLER_KEYS = {"onCreate", "onValue", "onTouch", "css"}

# Empty list keys — strip when list is empty.
EMPTY_LIST_KEYS = {"tabs", "widgets"}

# "padding" is "auto" by default but some panels use 0 (a real override), so
# be careful — we only strip when the value is literally the string "auto".
PADDING_AUTO = "auto"

# Variables default — strip only this exact string.
VARIABLES_DEFAULT = "@{parent.variables}"


def should_strip(key: str, value) -> bool:
    """Return True if this key/value pair is a known OSC default."""

    if key == "expand":
        return value in EXPAND_DEFAULTS

    if key == "padding":
        return value == PADDING_AUTO

    if key == "variables":
        return value == VARIABLES_DEFAULT

    if key in EMPTY_HANDLER_KEYS:
        return isinstance(value, str) and value.strip() == ""

    if key in EMPTY_LIST_KEYS:
        return isinstance(value, list) and len(value) == 0

    if key in UNIVERSAL_DEFAULTS:
        return value == UNIVERSAL_DEFAULTS[key]

    return False


removed_counts: dict[str, int] = {}


def clean_node(node):
    """Recursively clean a widget/tab node in-place."""
    if not isinstance(node, dict):
        return

    keys_to_remove = [k for k, v in node.items() if should_strip(k, v)]
    for k in keys_to_remove:
        del node[k]
        removed_counts[k] = removed_counts.get(k, 0) + 1

    # Recurse into the OSC root "content" wrapper
    if "content" in node:
        clean_node(node["content"])

    for child in node.get("widgets", []):
        clean_node(child)
    for child in node.get("tabs", []):
        clean_node(child)


def main():
    src = Path("osc_controller.json")
    dst = Path("osc_controller.clean.json")

    print(f"Loading {src} …")
    with src.open() as f:
        data = json.load(f)

    original_text = src.read_text()
    original_lines = original_text.count("\n") + 1

    # Deep copy so we can audit the diff
    cleaned = copy.deepcopy(data)
    clean_node(cleaned)

    print(f"Writing {dst} …")
    with dst.open("w") as f:
        json.dump(cleaned, f, indent=2)
        f.write("\n")

    cleaned_text = dst.read_text()
    cleaned_lines = cleaned_text.count("\n") + 1

    reduction = original_lines - cleaned_lines
    pct = reduction / original_lines * 100

    print()
    print(f"{'Original lines:':<30} {original_lines:>8,}")
    print(f"{'Cleaned lines:':<30} {cleaned_lines:>8,}")
    print(f"{'Lines removed:':<30} {reduction:>8,}  ({pct:.1f}%)")
    print()
    print("Properties stripped (by key):")
    for k, count in sorted(removed_counts.items(), key=lambda x: -x[1]):
        print(f"  {k:<30} {count:>5}")


if __name__ == "__main__":
    import os
    # Run from repo root
    os.chdir(Path(__file__).parent.parent)
    main()
