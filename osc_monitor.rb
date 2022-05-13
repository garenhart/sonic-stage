######################################
# osc_monitor.rb
# monitor/player part (Sonic Pi)
# no name yet for this project (Sonic Pi - Open Stage Control - Processing)
# author: Garen H.
######################################

#load libraries
eval_file get(:sp_path)+"lib/lib-chord-gen.rb"
eval_file get(:sp_path)+"lib/lib-impro.rb"
eval_file get(:sp_path)+"lib/lib-osc.rb"
eval_file get(:sp_path)+"lib/lib-dyn-live_loop.rb"
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
tonics_pattern = []
chords_pattern = []

define :reset_tonics do
  tonics = []
  tonics_pattern = []
  chords_pattern = []
end

# CONFIG
set :tempo, 60
set :pattern_mode, 0
set :pattern, 1
set :bass_inst, :fm
set :bass_amp, 0
set :chord_amp, 0
set :main_mode, 0
set :main_scale, :ionian
set :chord_type, 1
set :chord_inst, :piano

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
  osc "/chord_amp", get(:chord_amp)
  osc "/mode", get(:main_mode)
#  osc "/scale", "ionian"
  osc "/bass_points", tonics.length
  osc "/chord_points", tonics.length
  osc "/chord_type", get(:chord_type)
  osc "/bass_inst", :fm
  osc "/chord_inst", :piano
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
    gl_play_drum :bd_tek, get(:kick), get(:kick_amp), get(:kick_on)
  end
  
  live_loop :drum_snare do
    use_real_time
    use_bpm get(:tempo)
    sync :tick
    gl_play_drum :drum_snare_soft, get(:snare), get(:snare_amp), get(:snare_on)
  end
  
  live_loop :drum_hihat do
    use_real_time
    use_bpm get(:tempo)
    sync :tick
    gl_play_drum :drum_cymbal_closed, get(:hihat), get(:hihat_amp), get(:hihat_on)
  end
end
# END DRUM LOOPS

# CHORD LOOP
with_fx :reverb, room: 0.8, mix: 0.6 do |r|
  live_loop :chord do
    use_real_time
    use_bpm get(:tempo)
    use_synth get(:chord_inst)
    sync :tick
    gl_play_chords tonics, chords_pattern, get(:chord_amp), get(:main_scale), get(:pattern), get(:chord_type)
  end
end
#END CHORD LOOP

# BASS LOOP
with_fx :reverb, room: 0.6, mix: 0.4 do |r|
  live_loop :bass do
    use_real_time
    use_bpm get(:tempo)
    use_synth get(:bass_inst)
    puts "INST", get(:bass_inst)
    cue :tick
    gl_play_bass tonics, tonics_pattern, get(:bass_amp)
  end
end
#END BASS LOOP



# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
  addr = "/osc:#{get(:ip)}:#{get(:port)}/**"
  n = sync addr
  token = gl_parse_addr addr
  
  case token[1]
  when "tempo"
    set :tempo, n[0].to_i
    
  when "pattern"
    set :pattern, n[0].to_i
    
  when "pattern_mode"
    set :pattern_mode, n[0].to_i
    if n[0] == 1.0
      reset_tonics
    end
    
  when "switch_loop"
    set :loop_mode, n[0].to_i
    set :pattern_mode, 0 if n[0].to_i > 0
    
  when "bass_inst"
    set :bass_inst, n[0].to_sym
    
  when "bass_line"
    bass_points_pos = []
    tonics_pattern = []
    n.length.times do |i|
      val = n[i].round
      tonics_pattern.push val if i.even? # we only need X coord.
      bass_points_pos.push val
    end
    osc "/bass_points_pos", bass_points_pos.to_s # send back rounded positions to imitate "snap to grid"
    
  when "chord_inst"
    set :chord_inst, n[0].to_sym
    
  when "chord_line"
    chord_points_pos = []
    chords_pattern = []
    n.length.times do |i|
      val = n[i].round
      chords_pattern.push val if i.even? # we only need X coord.
      chord_points_pos.push val
    end
    osc "/chord_points_pos", chord_points_pos.to_s # send back rounded positions to imitate "snap to grid"
    
  when "chord_type"
    set :chord_type, n[0].to_i
    puts "TYPE", get(:chord_type)
    
  when "drums" # update Time State
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
  when "chord_amp"
    set :chord_amp, n[0]
    
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
    
    # save mode and scale
  when "mode"
    set :main_mode, n[0].to_i
  when "scale"
    set :main_scale, n[0].to_sym
    the_scale = get(:main_scale)
    puts "SSSSSSSSSSSSSSSSS", the_scale
    osc "/scale_match", (gl_notes_in_scale tonics, the_scale, tonics[0]) ? 1 : 0
    gl_reset_keyboard(tonics[0], the_scale)
  end
end
# END OSC MESSAGE MONITORING LOOP

# MIDI MESSAGE MONITORING LOOP
with_fx :reverb, room: 0.8, mix: 0.6 do
  live_loop :midi_monitor do
    use_real_time
    # use_bpm get(:tempo)
    # sync :tick
    
    note, velocity = sync midi_in + "note_on"
    loop = get(:loop_mode)
    pattern = get(:pattern)
    pattern_mode = get(:pattern_mode)
    case loop
    when 0
      case pattern
      when 1
        if pattern_mode == 1
          use_synth :piano
          play note
          tonics.push note
          tonic_names = gl_notes_to_names(tonics).to_s
          puts "TONICS", tonic_names
          osc "/bass_points", tonic_names
          osc "/chord_points", tonic_names
          
          bass_points_pos = []
          tonics_pattern = []
          chords_pattern = []
          tonics.length.times do |i|
            pos = dist_pos i, tonics.length, 16
            tonics_pattern.push pos
            chords_pattern.push pos
            bass_points_pos.push pos
            bass_points_pos.push 0 #arr vertical pos for osc
          end
          osc "/bass_points_pos", bass_points_pos.to_s
          osc "/chord_points_pos", bass_points_pos.to_s
          osc "/scale_match", (gl_notes_in_scale tonics, get(:main_scale), tonics[0]) ? 1 : 0
      end
    end
    when 1
      use_synth :piano
      play note
    end
  end
end
# END MIDI MESSAGE MONITORING LOOP
