# Plan: Refactor `osc_controller.json` for Efficiency

The file is ~12,280 lines — far larger than it needs to be. Every widget declares all 15–30 properties explicitly, even when equal to Open Stage Control's schema defaults. Structural duplication between bass/chord/drums also inflates the file, but since OSC JSON has no template/component system, only the *verbosity per widget* can be eliminated programmatically.

**Recommended approach**: Write a Python cleanup script to strip default-value properties, then manually extract repeated inline CSS patterns to the theme file.

---

## Phase 1 — Audit & Script Development

**Step 1.** Identify the exact set of safe-to-strip property/value pairs. These are properties that are NEVER meaningfully different from their OSC defaults throughout the file. Based on the current file, the primary candidates are:

- **Universal empties**: `"comments": ""`, `"html": ""`, `"css": ""` (when empty), `"linkId": ""`, `"preArgs": ""`, `"typeTags": ""`, `"target": ""`, `"onCreate": ""`, `"onValue": ""` (when empty)
- **Universal booleans (default false)**: `"ignoreDefaults": false`, `"bypass": false`, `"lock": false`, `"traversing": false`
- **Universal booleans (default true)**: `"visible": true`, `"interaction": true`, `"contain": true`, `"scroll": true`, `"innerPadding": true`
- **Universal "auto" colors**: `"colorText"`, `"colorWidget"`, `"colorStroke"`, `"colorFill"`, `"alphaStroke"`, `"alphaFillOff"`, `"alphaFillOn"`, `"lineWidth"`, `"borderRadius"`, `"padding"`, `"address"` — only when set to `"auto"`
- **Universal defaults**: `"decimals": 2`, `"default": ""`, `"value": ""`, `"layout": "default"`, `"justify": "start"`, `"gridTemplate": ""`, `"variables": "@{parent.variables}"`, `"tabs": []`, `"tabsPosition": "top"`
- **Positional defaults**: `"top": "auto"`, `"left": "auto"`, `"width": "auto"`, `"height": "auto"`, `"expand": false`

**Step 2.** Write `scripts/clean_osc_controller.py` that:
- Recursively walks all widget/tab nodes
- Removes properties matching the defaults above
- Writes output to `osc_controller.clean.json` (not overwriting the original)

**Step 3.** Review the diff to confirm correctness — spot-check 5–10 widgets of different types.

---

## Phase 2 — CSS Extraction

**Step 4.** Identify repeated inline `css` field patterns:
- `":host {\n  class: gh-button-control\n}"` — already a CSS class in the theme but re-declared inline on many buttons
- `"z-index: 0"` and `"z-index: 90"` on fx range/button overlays

**Step 5.** Add targeted CSS rules to `osc_controller_theme.css` using widget ID selectors (e.g., `[id$="_opt1_value"]`, `[id$="_name"]`), replacing per-widget inline `css` declarations.

---

## Phase 3 — Structural Cleanup

**Step 6.** Audit intermediate wrapper panels (`panel_bass_c`, `panel_bass_c2`, etc.) — some exist only for layout organization. Collapse any that can merge layout properties into their sole child without visual change.

**Step 7.** Remove `"tabsPosition": "top"` from any panels that also have `"tabs": []` (no tabs present).

---

## Phase 4 — Validation

**Step 8.** Open `osc_controller.clean.json` in Open Stage Control and verify:
- All sections render identically (bass, chord, drums, keys panels)
- All fx option panels (opt1/opt2) work — range sliders, name buttons, onValue callbacks
- OSC round-trip works with Sonic Pi (`sonic-stage.rb` running)

**Step 9.** If validation passes, replace `osc_controller.json` with the cleaned version (keep a backup).

---

## Relevant Files
- `osc_controller.json` — Main target (~12,280 lines)
- `osc_controller_theme.css` — CSS theme (already well-structured, ~50 lines)
- `osc_controller.js` — OSC filter (do not modify)
- `lib/lib-osc.rb` — Widget IDs/OSC paths must remain unchanged

## Verification Checklist
1. Line count: expect 40–60% reduction (target ~5,000–7,500 lines)
2. Visual parity in Open Stage Control
3. OSC end-to-end with `sonic-stage.rb`
4. FX opt panels + auto/update toggle behavior unchanged

## Decisions & Scope
- **In scope**: Property stripping, empty field removal, CSS extraction, wrapper panel cleanup
- **Out of scope**: Changing widget IDs, OSC paths, merging bass/chord sections (not possible in OSC JSON), any functional changes
- **Script-first**: Programmatic approach avoids human error on a 12k-line file
- **Non-destructive**: Original kept intact; script outputs to a separate file until validated

---

## Further Consideration
The `expand: "false"` string (vs `expand: false` boolean) appears in some widgets — the script should handle both forms consistently to avoid accidentally stripping a behavioral edge case. Worth a targeted grep before writing the script.
