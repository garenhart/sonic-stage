# Sonic Stage AI Coding Instructions

## Architecture Overview
Sonic Stage is a real-time music performance system integrating three components via OSC:
- **Sonic Pi** (audio generation) - Primary runtime environment
- **Open Stage Control** (UI) - Port 7777 for OSC communication
- **Processing** (visualizations, optional) - Port 8000 for OSC communication

## Critical Setup Requirements
- **Required**: Set `:ss_path` variable in Sonic Pi's `~/.sonic-pi/config/init.rb` with absolute path (no `~`)
- **Entry Point**: Always run `sonic-stage.rb` (wrapper) not `osc_monitor.rb` directly to prevent buffer overflow
- **Port Configuration**: OSC ports are hardcoded in `osc_monitor.rb` - ctrl_port: 7777, anim_port: 8000

## Configuration System
Musical arrangements are JSON-driven with this structure:
```ruby
cfg = initJSON(config_path + filename)  # Load via lib-io.rb
```
- `config/_default.json` - Base template configuration
- Named configs (e.g., `ambi.json`, `summer.json`) - Complete musical arrangements
- Structure: `{tempo, solo: {}, bass: {}, chord: {}, drums: {}}`
- **Effects arrays**: `[["reverb", 0.9, 0.5], ["compressor", [2.0, 2.0], [1.0, 1.0]]]`
- **Favorites system**: `fav` arrays contain curated synth/sample lists per instrument

## Core Library Architecture
**Load Order Matters**: Libraries loaded in `osc_monitor.rb` in dependency order:
1. `lib-util.rb` - Utility functions (string manipulation, ring operations)
2. `lib-io.rb` - JSON I/O (`initJSON`, `writeJSON`)  
3. `lib-fav.rb` - Favorites/sample management
4. `lib-fx.rb` - Effects chain processing (`fx_chain` function)
5. `lib-init.rb` - Configuration initialization and state management
6. `lib-osc-animation.rb` - Processing communication
7. `lib-play.rb` - Core playback engine
8. `lib-osc.rb` - OSC communication with Open Stage Control
9. `lib-dyn-live_loop.rb` - Dynamic live loop management (`runLoop`, `stopLoop`)

## Real-Time State Pattern
Uses Sonic Pi's global state for real-time coordination:
```ruby
set :drums_state, cfg['drums']    # Initialize from config
rt_drums = get(:drums_state)      # Read in live loops for real-time changes
```
State keys: `:bass_state`, `:chord_state`, `:drums`, `:ctrl_ip`, `:ctrl_port`

## OSC Communication Patterns
**Outbound to UI**: `osc_ctrl(path, *args)` sends to Open Stage Control
```ruby
osc_ctrl "/current_beat", beat_number
osc_ctrl "/synths", json_string_of_options  # Populate UI dropdowns
```
**Inbound from UI**: OSC handlers update global state and trigger actions
- Bidirectional sync keeps UI and audio engine synchronized

## Dynamic Live Loop System
```ruby
runLoop("loop_name") { /* loop body */ }  # Start named loop
stopLoop("loop_name")                     # Stop by name
```
- **Pattern**: Each instrument (bass, chord, drums) runs in separate live loops
- **Synchronization**: `sync :tick` coordinates timing between loops
- **State Control**: Global variables control loop behavior without stopping/starting

## Effects Chain Architecture  
Effects defined as nested arrays in config, processed by `fx_chain()`:
```ruby
with_effects fx_chain(instrument['fx']) do
  # playback code
end
```
**Pattern**: Each instrument can have multiple effects with individual parameters

## Development Workflows
**Configuration Testing**: 
```ruby 
cfg = initJSON(config_path + "test_config.json")
init_osc_controls cfg, true  # Second param reinitializes
```
**Live Development**: Modify library files and re-run `eval_file lib_path + 'lib-name.rb'`
**OSC Debugging**: Set `use_osc_logging true` in main file

## Key Conventions
- **Function naming**: `define :snake_case_name` for all functions
- **File naming**: `lib-{category}.rb` for library modules 
- **Config naming**: Descriptive names with optional state suffixes (`(anim)`, `(final)`)
- **OSC paths**: Start with `/` and use snake_case: `/cfg_path`, `/current_beat`
- **Error handling**: Prefer graceful degradation over exceptions in real-time contexts
- **Timing**: Use `density` and `sleep rhythm` for tempo-relative timing

## Common Integration Points
- **MIDI Input**: Generic `/midi*/` pattern handles most MIDI devices
- **Sample Management**: `sample_group()` function extracts group from sample names
- **UI Sync**: `init_osc_controls()` populates UI with available synths/samples/effects
- **Visual Sync**: Animation cues sent via OSC to Processing on port 8000

## Performance Considerations
- Real-time audio requires minimal function call overhead in live loops
- Configuration changes update global state without restarting loops
- Buffer management handled by `sonic-stage.rb` wrapper pattern
- Effects processing can impact latency - order matters in `fx_chain`