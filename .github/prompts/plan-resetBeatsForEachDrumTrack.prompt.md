# Plan: Reset Beats for Each Drum Track

## Summary
Add a "clear beats" reset button per drum track (kick, snare, cymbal) that clears all active beats to 0, updates the Sonic Pi real-time playback state, and syncs the UI beat matrix in Open Stage Control.

**Decisions:**
- Reset scope: beats only (not amp, sample, fx, etc.)
- Beats reset to: all-zeros string matching current `cfg['drums']['count']` length
- UI placement: as a child widget inside `panel_*_add` for each drum track

---

## Steps

### Phase 1: Backend — lib-mon.rb

1. In `lib/lib-mon.rb`, inside `drum_mon`, add a new `when` case for `"#{inst}_reset_beats"` — insert between the `"#{inst}_beats"` case and the `else` clause:
   - `cfg['drums'][inst]['beats'] = "0" * cfg['drums']['count']` — clear using live count (not hardcoded 16)
   - `init_time_state_drums cfg` — push cleared state to global playback state
   - `osc_ctrl "/#{inst}_beats_v", cfg['drums'][inst]['beats']` — sync UI matrix widget

### Phase 2: UI — osc_controller.json

2. For each of kick, snare, cymbal, add a `"tap"` button widget into the currently-empty `"widgets": []` of the corresponding `panel_*_add` panel:
   - `panel_kick_add` (line 10278) → id `"kick_reset_beats"`
   - `panel_snare_add` (line 8426) → id `"snare_reset_beats"`
   - `panel_cymbal_add` (line 6572) → id `"cymbal_reset_beats"`
   - `type`: `"button"`, `mode`: `"tap"`, `on`: 1, `off`: 0
   - `label`: reset icon (e.g. `"^arrows-rotate"` or `"CLR"`)
   - `address`: `"auto"` (will auto-derive OSC path from id)
   - `onValue`: `""` — no additional script needed
   - Copy width/height/styling from `kick_inst_prev` (tap button template at line 10327); size to fit inside the `"width": "5%"` panel

---

## Relevant Files

- `lib/lib-mon.rb` — `drum_mon` function — add `when "#{inst}_reset_beats"` case
- `osc_controller.json` — Add button into `widgets` of `panel_kick_add` (line 10278), `panel_snare_add` (line 8426), `panel_cymbal_add` (line 6572)

## Verification

1. Set some beats on kick, click reset → all kick beat buttons go dark/off
2. Change beat count (e.g. to 32), set beats, click reset → all 32 beats clear
3. Verify snare reset and cymbal reset independently
4. With `drums_auto` off: reset clears beats locally, changes apply on next loop
5. Active playback: after reset, drum stops playing within the current pattern cycle
