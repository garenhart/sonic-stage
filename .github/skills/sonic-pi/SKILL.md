---
name: sonic-pi
description: "Sonic Pi Ruby API reference and patterns. Use when: writing Sonic Pi code, creating synths, samples, live loops, effects, ADSR envelopes, OSC communication, MIDI, scales, chords, rings, randomisation, or real-time audio coding."
---

# Sonic Pi Reference

## When to Use
- Writing or modifying Sonic Pi Ruby code
- Creating synths, samples, live loops, or effects
- Working with scales, chords, rings, or randomisation
- Setting up OSC or MIDI communication
- Debugging audio timing or envelope issues

## Core Audio Functions

### Playing Notes
```ruby
play 60                                  # Play MIDI note 60
play :e3                                 # Play by note name
play 60, amp: 0.5, pan: -1              # With options
play chord(:E3, :minor)                 # Play chord
play_pattern_timed scale(:c3, :major), 0.125  # Play scale
```

### Synths
```ruby
use_synth :prophet                       # Set current synth
synth :tb303, note: :e1, cutoff: 100    # Trigger specific synth
s = synth :prophet, note: :e1, release: 8  # Capture node for control
control s, note: 65, cutoff: 130        # Control running synth
```

Popular synths: `:prophet`, `:dsaw`, `:fm`, `:tb303`, `:pulse`, `:blade`, `:beep`, `:tri`, `:saw`, `:square`, `:dpulse`, `:dtri`, `:piano`

### Samples
```ruby
sample :loop_amen                        # Play built-in sample
sample :loop_amen, rate: 0.5            # Half speed (lower pitch)
sample :loop_amen, rate: -1             # Reverse
sample :loop_amen, beat_stretch: 2      # Stretch to 2 beats
sample :bd_haus, start: 0.25, finish: 0.5  # Partial playback
sample "/path/to/file.wav"              # External sample
```

Sample prefixes: `:ambi_`, `:bass_`, `:elec_`, `:perc_`, `:guit_`, `:drum_`, `:misc_`, `:bd_`, `:loop_`

### ADSR Envelopes
```ruby
play 60, attack: 0.5, decay: 0.2, sustain: 1, release: 2
play 60, attack: 0.1, attack_level: 1, decay: 0.2, decay_level: 0.5,
  sustain: 1, sustain_level: 0.5, release: 0.5
# Duration = attack + decay + sustain + release
```

## Timing & Structure

### Sleep and BPM
```ruby
sleep 1                   # Wait 1 beat
sleep 0.5                 # Half beat
use_bpm 120               # Set tempo
use_bpm 60                # Default
```

### Live Loops
```ruby
live_loop :drums do
  sample :bd_haus
  sleep 0.5
end

live_loop :bass do
  sync :drums              # Sync to another loop's cue
  use_synth :tb303
  play :e1, release: 0.3
  sleep 1
end
```

### Threads and Cue/Sync
```ruby
in_thread do
  loop do
    cue :tick
    sleep 1
  end
end

in_thread do
  loop do
    sync :tick
    sample :drum_heavy_kick
  end
end
```

### Functions
```ruby
define :my_riff do |note, dur|
  use_synth :dsaw
  play note, release: dur
end
my_riff :e3, 0.5
```

## Effects (FX)
```ruby
with_fx :reverb, room: 0.8 do
  play 50
end

with_fx :echo, phase: 0.25, decay: 4 do
  sample :loop_amen
end

# Chaining
with_fx :reverb do
  with_fx :distortion do
    play 50
  end
end

# Controlling FX
with_fx :reverb do |r|
  play 50
  sleep 1
  control r, mix: 0.9
end
```

Common FX: `:reverb`, `:echo`, `:distortion`, `:slicer`, `:wobble`, `:flanger`, `:lpf`, `:hpf`, `:rhpf`, `:rlpf`, `:compressor`, `:bitcrusher`, `:eq`, `:tremolo`, `:whammy`, `:pan`, `:ring_mod`, `:vowel`, `:ixi_techno`, `:gverb`

## Data Structures

### Rings
```ruby
r = (ring 60, 62, 64)     # Wrapping ring
r[0]                       # => 60
r[3]                       # => 60 (wraps)
r.tick                     # Auto-increment index
r.look                     # Current tick value without advancing
r.choose                   # Random element
r.shuffle                  # Shuffled copy
r.reverse                  # Reversed copy
```

### Scales and Chords
```ruby
scale(:e3, :minor_pentatonic)            # Returns ring
scale(:c3, :major, num_octaves: 2)       # Multi-octave
chord(:E3, :minor)                       # E minor chord
chord(:E3, :m7)                          # Minor 7th
chord(:E3, :dom7)                        # Dominant 7th
```

### Tick System
```ruby
live_loop :arp do
  play (scale :e3, :minor_pentatonic).tick, release: 0.1
  sleep 0.125
end
# Named ticks for multiple counters:
play notes.tick(:melody)
sleep durations.tick(:rhythm)
```

## Randomisation
```ruby
rand                       # 0 to 1 float
rrand(50, 100)             # Float in range
rrand_i(50, 100)           # Integer in range
dice                       # 1-6
one_in(3)                  # true with 1/3 probability
choose([1, 2, 3])          # Random from list
use_random_seed 42         # Reproducible randomness
```

## State (Thread-Safe)
```ruby
set :my_val, 100           # Set global state
get[:my_val]               # Read state (returns 100)
# Use set/get across live_loops instead of variables
```

## OSC Communication
```ruby
# Receiving
live_loop :osc_listener do
  use_real_time
  a, b, c = sync "/osc*/trigger/prophet"
  synth :prophet, note: a, cutoff: b, sustain: c
end

# Sending
use_osc "localhost", 4560
osc "/hello/world", 1, 2, 3
```

## MIDI
```ruby
# Receiving
live_loop :midi_piano do
  use_real_time
  note, velocity = sync "/midi*/note_on"
  synth :piano, note: note, amp: velocity / 127.0
end

# Sending
midi_note_on :e3, 100
midi_note_off :e3
midi :e3, sustain: 0.1      # Note on + off shortcut
midi_cc 1, 64                # Control change
```

## Sliding (Smooth Transitions)
```ruby
s = play 60, release: 8, note_slide: 1
sleep 1
control s, note: 72          # Slides over 1 beat
# Every controllable opt has a _slide counterpart
```

## Useful Functions
```ruby
sample_duration :loop_amen   # Duration in beats
use_synth_defaults release: 0.2, cutoff: 80
density 2 do ... end         # Double speed inside block
spread(3, 8)                 # Euclidean rhythm => ring of booleans
knit(:e3, 3, :g3, 1)        # Repeat pattern
octs(:e3, 3)                # Octave ring [e3, e4, e5]
line(0, 1, steps: 10)       # Linear progression ring
```
