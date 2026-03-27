#!/usr/bin/env python3
"""
phase2_css_extract.py

Phase 2 CSS extraction for osc_controller.clean.json:
  1. Normalises inconsistent `:host { class: X }` whitespace
  2. Replaces repeated inline CSS blocks with CSS class references,
     adding the corresponding class rules to osc_controller_theme.css

Run AFTER clean_osc_controller.py:
    python3 scripts/phase2_css_extract.py

Edits osc_controller.clean.json in-place.
"""

import json
import re
from pathlib import Path

# ---------------------------------------------------------------------------
# CSS class definitions to add to the theme file
# ---------------------------------------------------------------------------
NEW_THEME_CLASSES = """
/* Modal popup opacity classes (applied via :host { class: X }) */
:host(.gh-modal-inst) .popup {
    opacity: 0.9;
}

:host(.gh-modal-reset) .popup {
    opacity: 0.95;
}

/* ADSR overlay multixy widget */
:host(.gh-adsr-overlay) {
    background: transparent;
    z-index: 10000;
}
"""

# ---------------------------------------------------------------------------
# Replacement map: OLD inline css value → NEW class-reference css value
# ---------------------------------------------------------------------------
CSS_REPLACEMENTS = {
    # modal instrument popup (6 occurrences)
    ".popup {\n  opacity:0.9;\n}": ":host {\n  class: gh-modal-inst\n}",

    # modal reset-beats popup (3 occurrences)
    ".popup { opacity:0.95; }": ":host {\n  class: gh-modal-reset\n}",

    # ADSR overlay multixy (6 occurrences)
    ":host {\nbackground: transparent;\nz-index: 10000;\n}": ":host {\n  class: gh-adsr-overlay\n}",
}

# Normalise inconsistent :host { class: X } whitespace variations
# Pattern: `:host {\nclass: X \n}` or `:host {\nclass: X\n}` (no indent)
# Target:  `:host {\n  class: X\n}`
_HOST_CLASS_RE = re.compile(r":host \{\n\s*class:\s*(\S+)\s*\n\}", re.MULTILINE)


def normalise_host_class(css_value: str) -> str:
    """Normalise :host { class: X } to canonical 2-space-indent form."""
    return _HOST_CLASS_RE.sub(lambda m: f":host {{\n  class: {m.group(1)}\n}}", css_value)


substitutions: dict[str, int] = {}
normalised_count = 0


def process_node(node):
    global normalised_count
    if not isinstance(node, dict):
        return

    if "css" in node:
        original = node["css"]
        # Apply explicit replacements first
        if original in CSS_REPLACEMENTS:
            replacement = CSS_REPLACEMENTS[original]
            node["css"] = replacement
            substitutions[replacement] = substitutions.get(replacement, 0) + 1
        else:
            # Normalise whitespace in existing class references
            normalised = normalise_host_class(original)
            if normalised != original:
                node["css"] = normalised
                normalised_count += 1

    if "content" in node:
        process_node(node["content"])
    for child in node.get("widgets", []):
        process_node(child)
    for child in node.get("tabs", []):
        process_node(child)


def main():
    json_path = Path("osc_controller.clean.json")
    theme_path = Path("osc_controller_theme.css")

    print(f"Loading {json_path} …")
    with json_path.open() as f:
        data = json.load(f)

    original_text = json_path.read_text()
    original_lines = original_text.count("\n") + 1

    process_node(data)

    with json_path.open("w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")

    cleaned_text = json_path.read_text()
    cleaned_lines = cleaned_text.count("\n") + 1

    print(f"  JSON lines: {original_lines:,} → {cleaned_lines:,} ({cleaned_lines - original_lines:+,})")
    print(f"  CSS block replacements: {sum(substitutions.values())}")
    print(f"  :host class normalisations: {normalised_count}")

    # Append new CSS classes to theme file (only if not already present)
    theme_text = theme_path.read_text()
    if "gh-modal-inst" not in theme_text:
        print(f"\nAppending new classes to {theme_path} …")
        with theme_path.open("a") as f:
            f.write(NEW_THEME_CLASSES)
        print("  Done.")
    else:
        print(f"\n{theme_path}: classes already present, skipping.")


if __name__ == "__main__":
    import os
    os.chdir(Path(__file__).parent.parent)
    main()
