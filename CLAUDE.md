# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

Sonic Stage is a real-time music performance system integrating three components via OSC (Open Sound Control):
- **Sonic Pi** (audio generation) — the primary runtime; all `.rb` files run inside Sonic Pi
- **Open Stage Control** (UI) — sends/receives OSC on port 7777
- **Processing** (visualizations, optional) — receives OSC on port 8000

## Running the System

**Prerequisite**: Set `:ss_path` in `~/.sonic-pi/config/init.rb` with an absolute path (no `~`):
```ruby
set :ss_path, "/Users/username/dev/sonic-stage/"
```

**Entry point**: Load `sonic-stage.rb` in Sonic Pi — never `osc_monitor.rb` directly. The wrapper exists to prevent buffer overflow.

**Open Stage Control setup**: osc-port `7777`, load `osc_controller.json`, custom-module `osc_controller.js`, theme `osc_controller_theme.css`, send to `127.0.0.1:4560`.

## Library Load Order

Libraries are loaded in `osc_monitor.rb` in dependency order. This matters — do not reorder:

1. `lib-util.rb` — string/ring utilities
2. `lib-io.rb` — `initJSON`, `writeJSON`
3. `lib-fav.rb` — favorites/sample management
4. `lib-fx.rb` — `fx_chain()` effects processing
5. `lib-init.rb` — config initialization and state management
6. `lib-osc-animation.rb` — Processing communication via `osc_anim`
7. `lib-play.rb` — core playback engine (drums, bass, chord, solo)
8. `lib-osc.rb` — OSC handlers for Open Stage Control
9. `lib-dyn-live_loop.rb` — `runLoop` / `stopLoop`
10. `lib-chord-gen.rb` — chord generation
11. `lib-mon.rb` — monitors/live loops entry point

## Configuration System

Configs are JSON files in `config/`. `_default.json` is the base template. Named configs (e.g., `summer.json`) are complete arrangements. Config structure:
```json
{
  "tempo": 120,
  "solo": { "inst": "piano", "fx": [["reverb", 0.9, 0.5], ["none", ...]], ... },
  "bass": { "synth": "fm", "tonics": [], "pattern": [], "fx": [...], ... },
  "chord": { "type": 1, "synth": "piano", "tonics": [], "pattern": [], ... },
  "drums": { "count": 16, "kick": { "beats": "0000000000000000", ... }, ... }
}
```
- **Effects arrays**: `[["reverb", room_size, mix], ["compressor", [attack, ...], [threshold, ...]]]`
- **Drum beats**: 16-character string of `"0"`/`"1"` per drum instrument
- **`fav` arrays**: curated synth/sample lists shown in UI dropdowns

Load a config: `cfg = initJSON(config_path + "filename.json")`

## Real-Time State Pattern

Sonic Pi's global state coordinates live loops and UI updates:
```ruby
set :drums_state, cfg['drums']    # initialize from config
rt_drums = get(:drums_state)      # read inside live loops for real-time changes
```
Key state variables: `:bass_state`, `:chord_state`, `:drums`, `:tempo`, `:ctrl_ip`, `:ctrl_port`, `:anim_ip`, `:anim_port`.

The `auto` flag on each instrument section controls whether loops read real-time state (`get(...)`) or use cached values — this is how UI changes take effect without stopping loops.

## Dynamic Live Loop System

```ruby
runLoop("loop_name") { /* loop body */ }
stopLoop("loop_name")
```
Each instrument (bass, chord, drums/kick/snare/cymbal, solo, cue) runs in its own named live loop. All loops sync on `:tick` emitted by `play_cue`. Stopping/starting loops is avoided in favor of toggling state flags.

## OSC Communication

**Outbound to UI** via `osc_ctrl(path, *args)`:
```ruby
osc_ctrl "/current_beat", beat_number
osc_ctrl "/synths", json_string   # populate UI dropdowns
```

**Outbound to Processing** via `osc_anim(path, *args)`:
- `/drum` — `instrument:String, amp:Float, beat_on:Int, on:Int`
- `/key` — `instrument:String, note:Int, amp:Float`

**Inbound from UI**: OSC handlers in `lib-osc.rb` update global state via `set`.

## Effects Chain

```ruby
with_effects fx_chain(instrument['fx']) do
  # playback code
end
```
`fx_chain` in `lib-fx.rb` converts the nested array format into nested `with_fx` blocks. Effect order matters for latency and sound character.

## Development Workflow

**Live reload a library** (without restarting):
```ruby
eval_file lib_path + 'lib-name.rb'
```

**OSC debugging**: Set `use_osc_logging true` at the top of `osc_monitor.rb`.

**Test a config change**:
```ruby
cfg = initJSON(config_path + "test_config.json")
init_osc_controls cfg, true  # true = reinitialize
```

## Performance

Real-time audio is the top priority. Not all code has equal timing sensitivity:

- **Critical path** — `play_drum`, `play_bass`, `play_chords`, `play_cue`, and the MIDI live loops run on the audio thread. Minimize `get`/`set` calls, avoid unnecessary function calls, and prefer local variable capture over repeated `get()` calls when the value doesn't need live updates mid-loop.
- **Non-critical** — `live_loop :osc_monitor`, initialization, and all `init_osc_*` functions are event-driven or one-shot; overhead there has no timing impact.
- **Effects ordering** — the order of entries in `fx` arrays affects both latency and sound character; keep chains short in production configs.

## Conventions

- Functions: `define :snake_case_name`
- Library files: `lib-{category}.rb`
- Config variants: descriptive names with optional suffixes — `(anim)` for animation-enabled, `(final)` for production versions
- OSC paths: `/snake_case` (e.g., `/cfg_path`, `/current_beat`)
- `rhythm = 1.0` is a whole note at the current BPM; all sleep values are multiples of this
- Prefer graceful degradation over exceptions in real-time audio contexts
