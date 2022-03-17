######################################
# osc_monitor.rb
# drum pad monitor/player
# Sonic Pi - Open Stage Control (poc)
# author: Garen H.
######################################
eval_file get(:sp_path)+"lib/lib-impro.rb" # Load library
eval_file get(:sp_path)+"lib/lib-dyn-live_loop.rb" # Load library
#require get(:sp_path)+"lib/modes.rb" # Load extra scales and chords from separate file
#ModeScales = Modes.scales

use_debug false

# generic midi definitions
midi_in = "/midi*midi*/"
midi_daw = "/midi*m_daw*/"
#######

set :ip, "127.0.0.1"
set :port, 7777 # make sure to match Open Stage Control's osc-port value
use_osc get(:ip), get(:port)

use_random_seed 31
prog = [{tonic: :D, type: 'm7-5', invert: -1}, {tonic: :G, type: '7', invert: -1},{tonic: :C, type: 'mM7', invert: 1}]

tonics = []

define :reset_tonics do
  tonics = []
end

define :parse_addr do |path|
  e = get_event(path).to_s
  v = e.split(",")[6]
  if v != nil
    return v[3..-2].split("/")
  else
    return ["error"]
  end
end

# CONFIG
set :tempo, 60
set :pattern_mode, 0
set :pattern, 1
set :bass_amp, 0.5


# DRUM CONFIG
set :kick_on, false
set :snare_on, false
set :hihat_on, false
set :kick, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :snare, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :hihat, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :kick_amp, 0.5
set :snare_amp, 0.5
set :hihat_amp, 0.5
kick = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
snare = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
hihat = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :loop_mode, 0

define :init_drum do |d|
  osc "/#{d}", 0
  osc "/#{d}_amp", 0.5
  16.times do |i|
    osc "/#{d}_beats/#{i}", 0
  end
end

define :init_drums do
  init_drum "kick"
  init_drum "snare"
  init_drum "hihat"
  osc "/drums", 0
end

define :init_controls do
  osc "/tempo", get(:tempo)
  osc "/pattern_mode", get(:pattern_mode)
  osc "/pattern", get(:pattern)
  osc "/switch_loop", get(:loop_mode)
  osc "/bass_amp", get(:bass_amp)
  init_drums
end


init_controls

# END DRUM CONFIG

# DRUM LOOPS
with_fx :reverb, room: 0.8, mix: 0.5 do |r|
  live_loop :drum_kick do
    use_real_time
    use_bpm get(:tempo)
    sync :tick
    li_play_drum :bd_tek, get(:kick), get(:kick_amp), get(:kick_on)
  end
  
  live_loop :drum_snare do
    use_real_time
    use_bpm get(:tempo)
    sync :tick
    li_play_drum :drum_snare_soft, get(:snare), get(:snare_amp), get(:snare_on)
  end
  
  live_loop :drum_hihat do
    use_real_time
    use_bpm get(:tempo)
    sync :tick
    li_play_drum :drum_cymbal_closed, get(:hihat), get(:hihat_amp), get(:hihat_on)
  end
end
# END DRUM LOOPS

# BASS LOOP
with_fx :reverb, room: 0.4, mix: 0.4 do |r|
  live_loop :bass do
    use_real_time
    use_bpm get(:tempo)
    use_synth :fm
    cue :tick
    li_play_bass get(:pattern_mode), tonics, 0, get(:bass_amp)
  end
end
#END BASS LOOP

# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
  addr = "/osc:#{get(:ip)}:#{get(:port)}/**"
  n = sync addr
  token = parse_addr addr
  
  case token[1]
  when "tempo"
    set :tempo, n[0].to_i
    puts "tempo", get(:tempo)
    
  when "pattern"
    set :pattern, n[0].to_i
    puts "style", get(:pattern)
    
  when "pattern_mode"
    set :pattern_mode, n[0].to_i
    puts "pattern mode", get(:pattern_mode)
    if n[0] == 1.0
      reset_tonics
    else
      bass_pattern = []
      tonics.length.times do |i|
        bass_pattern.push i
        bass_pattern.push 0
      end
      puts "bass line", bass_pattern
      osc "/bass_points", tonics.length
      osc "/bass_points_pos", bass_pattern.to_s
    end
    
  when "switch_loop"
    set :loop_mode, n[0].to_i
    puts "loop_mode", get(:loop_mode)
    
  when "bass_line"
    puts "bass line", n[0].round, n[2].round, n[4].round, n[6].round
    
  when "drums" # update Time State
    puts "DRUMS:", n
    if n[0] == 0.0
      set :kick, kick
      set :snare, snare
      set :hihat, hihat
    end
    # set drum "on" status based on the button state
  when "kick"
    set :kick_on, n[0]==1.0
  when "snare"
    set :snare_on, n[0]==1.0
  when "hihat"
    set :hihat_on, n[0]==1.0
    
    #set amp
  when "bass_amp"
    set :bass_amp, n[0]
    
  when "kick_amp"
    set :kick_amp, n[0]
  when "snare_amp"
    set :snare_amp, n[0]
  when "hihat_amp"
    set :hihat_amp, n[0]
    
    # save beat states
  when "kick_beats"
    kick[token[2].to_i] = n[0].to_i
  when "snare_beats"
    snare[token[2].to_i] = n[0].to_i
  when "hihat_beats"
    hihat[token[2].to_i] = n[0].to_i
  end
end
# END OSC MESSAGE MONITORING LOOP

# MIDI MESSAGE MONITORING LOOP
live_loop :midi_in do
  use_real_time
  #use_bpm get(:tempo)
  #sync :tick
  
  note, velocity = sync midi_in + "note_on"
  puts "NNNNN", note
  pattern = get(:pattern)
  pattern_mode = get(:pattern_mode)
  puts "pattern mode: ", pattern_mode
  puts "pattern: ", pattern
  
  case pattern
  when 1
    if pattern_mode == 1
      use_synth :fm
      play note
      tonics.push note
      puts "Tonics", tonics, tonics.length
      osc "/bass_points", tonics.length
    end
  end
end
# END MIDI MESSAGE MONITORING LOOP
