######################################
# osc_monitor.rb
# monitor/player part (Sonic Pi)
# no name yet for this project (Sonic Pi - Open Stage Control - Processing)
# author: Garen H.
######################################

#load libraries
eval_file get(:sp_path)+"lib/lib-io.rb"
eval_file get(:sp_path)+"lib/lib-chord-gen.rb"
eval_file get(:sp_path)+"lib/lib-osc-animation.rb"
eval_file get(:sp_path)+"lib/lib-impro.rb"
eval_file get(:sp_path)+"lib/lib-osc.rb"
eval_file get(:sp_path)+"lib/lib-dyn-live_loop.rb"
#require get(:sp_path)+"lib/modes.rb" # Load extra scales and chords from separate file
#ModeScales = Modes.scales

use_debug false

# generic midi definitions
midi_in = "/midi:nanokey*/" # Korg nanoKey
# midi_in = "/midi*midi*/" # Komplete Kontrol M32
midi_daw = "/midi*m_daw*/" # Komplete Kontrol M32 
#######

# config IO JSON
# deserialize JSON file into cfg hash
cfg = gl_readJSON("default")

puts "cfg", cfg

# Open Stage Control config
set :ctrl_ip, "127.0.0.1"
set :ctrl_port, 7777 # make sure to match Open Stage Control's osc-port value
# Processing config
set :anim_ip, "127.0.0.1"
set :anim_port, 8000 # make sure to match Processing osc-port value

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
# set :tempo, cfg['tempo']
# set :pattern_mode, cfg['pattern_mode']
# set :pattern, cfg['pattern']
# set :main_mode, cfg['mode']
# set :main_scale, cfg['scale']
# set :bass_inst, cfg['bass']['synth']
# set :bass_amp, cfg['bass']['amp']
# set :chord_type, cfg['chord']['type']
# set :chord_inst, cfg['chord']['synth']
# set :chord_amp, cfg['chord']['amp']

# DRUM CONFIG
# set :kick_inst_group, cfg['kick']['sample_group']
# set :kick_inst, cfg['kick']['sample']
# set :snare_inst_group, cfg['snare']['sample_group']
# set :snare_inst, cfg['snare']['sample']
# set :cymbal_inst_group, cfg['cymbal']['sample_group']
# set :cymbal_inst, cfg['cymbal']['sample']
# set :kick_amp, cfg['kick']['amp']
# set :snare_amp, cfg['snare']['amp']
# set :cymbal_amp, cfg['cymbal']['amp']

# set :drum_tempo_factor, 1

# set :kick_on, false
# set :snare_on, false
# set :cymbal_on, false
# kick = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
# snare = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
# cymbal = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

set :kick, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :snare, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :cymbal, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :loop_mode, 0

define :init_drum do |d, gr_ctrl, inst_ctrl, cfg|
  gl_osc_ctrl "/#{d}", 0
  gl_osc_ctrl "/#{d}_amp", cfg[d]['amp']
  gl_osc_ctrl gr_ctrl, cfg[d]['sample_group']
  gl_populate_samples inst_ctrl + "_v", (cfg[d]['sample_group']).to_sym
  sleep 0.125 # sleeping between populating and selecting seems to make it work 
  gl_osc_ctrl inst_ctrl, (cfg[d]['sample']).to_s
  16.times do |i|
    gl_osc_ctrl "/#{d}_beats/#{i}", cfg[d]['beats'][i] #should figure out how to populate beats without looping through array
  end
  # gl_osc_ctrl "/#{d}_beats", cfg[d]['beats']
  set (d.to_sym), cfg[d]['beats'] #set the beats to for the drum
end

define :init_drums do
  gl_osc_ctrl "/drums", 1
  gl_osc_ctrl "/dropdown_drum_tempo_factor", 1
  init_drum "kick", "/kick_inst_groups", "/kick_inst", cfg
  init_drum "snare", "/snare_inst_groups", "/snare_inst", cfg
  init_drum "cymbal", "/cymbal_inst_groups", "/cymbal_inst", cfg
end

define :init_controls do
  gl_osc_ctrl "/tempo", cfg['tempo']
  gl_osc_ctrl "/pattern_mode", cfg['pattern_mode']
  gl_osc_ctrl "/pattern", cfg['pattern']
  gl_osc_ctrl "/switch_loop", get(:loop_mode)
  gl_osc_ctrl "/bass_amp", cfg['bass']['amp']
  gl_osc_ctrl "/chord_amp", cfg['chord']['amp']
  gl_osc_ctrl "/mode", cfg['mode']
#  gl_osc_ctrl "/scale", "ionian"
  gl_osc_ctrl "/bass_points", tonics.length
  gl_osc_ctrl "/chord_points", tonics.length
  gl_osc_ctrl "/chord_type", cfg['chord']['type']
  gl_osc_ctrl "/bass_inst", cfg['bass']['synth']
  gl_osc_ctrl "/chord_inst", cfg['chord']['synth']
  gl_reset_keyboard(tonics[0], cfg['scale'])
  init_drums
end

init_controls

# END DRUM CONFIG

# DRUM LOOPS
with_fx :reverb, room: 0.8, mix: 0.5 do |r|
  use_osc get(:anim_ip), get(:anim_port)
  live_loop :drum_kick do
    gl_play_drum "kick", **cfg
  end
  
  live_loop :drum_snare do
    gl_play_drum "snare", **cfg
  end
  
  live_loop :drum_cymbal do
    gl_play_drum "cymbal", **cfg
  end
end
# END DRUM LOOPS

# CHORD LOOP
with_fx :reverb, room: 0.8, mix: 0.6 do |r|
  live_loop :chord do
    use_real_time
    use_bpm cfg['tempo']
    use_synth (cfg['chord']['synth']).to_sym
    sync :tick
    gl_play_chords tonics, chords_pattern, cfg['chord']['amp'], cfg['scale'], cfg['pattern'], cfg['chord']['type']
  end
end
#END CHORD LOOP

# BASS LOOP
with_fx :reverb, room: 0.6, mix: 0.4 do |r|
  use_osc get(:anim_ip), get(:anim_port)
  live_loop :bass do
    use_real_time
    use_bpm cfg['tempo']
    use_synth cfg['bass']['synth'].to_sym
    puts "INST", cfg['bass']['synth']
    cue :tick
    gl_play_bass tonics, tonics_pattern, cfg['bass']['amp']
  end
end
#END BASS LOOP

# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
  use_osc get(:ctrl_ip), get(:ctrl_port)
  addr = "/osc:#{get(:ctrl_ip)}:#{get(:ctrl_port)}/**"
  n = sync addr
  token = gl_parse_addr addr
  
  case token[1]
  when "tempo"
    cfg['tempo'] = n[0].to_i
    
  when "pattern"
    cfg['pattern'] = n[0].to_i
    
  when "pattern_mode"
    cfg['pattern_mode'] = n[0].to_i
    if n[0] == 1.0
      reset_tonics
    end
    
  when "switch_loop"
    set :loop_mode, n[0].to_i
    cfg['pattern_mode'] = 0 if n[0].to_i > 0
    
  when "bass_inst"
    cfg['bass']['synth'] = n[0].to_sym
    
  when "bass_line"
    bass_points_pos = []
    tonics_pattern = []
    n.length.times do |i|
      val = n[i].round
      tonics_pattern.push val if i.even? # we only need X coord.
      bass_points_pos.push val
    end
    osc "/bass_points_pos", *bass_points_pos # send back rounded positions to imitate "snap to grid"
    
  when "chord_inst"
    cfg['chord']['synth'] = n[0].to_sym
    
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
    cfg['chord']['type'] = n[0].to_i
    puts "TYPE", cfg['chord']['type']

  when "dropdown_drum_tempo_factor" # update Time State
    cfg['drum_tempo_factor'] = n[0].to_i
    
  when "drums" # update Time State
    if n[0] == 0.0
      set :kick, cfg['kick']['beats']
      set :snare, cfg['snare']['beats']
      set :cymbal, cfg['cymbal']['beats']
    end

  when "kick_inst_groups"
    puts "KICK_INST", n[0].to_sym
    gl_populate_samples "/kick_inst_v", n[0].to_sym
  when "kick_inst"
    cfg['kick']['sample'] = n[0].to_sym
  when "snare_inst_groups"
    gl_populate_samples "/snare_inst_v", n[0].to_sym
  when "snare_inst"
    cfg['snare']['sample'] = n[0].to_sym
  when "cymbal_inst_groups"
    gl_populate_samples "/cymbal_inst_v", n[0].to_sym
  when "cymbal_inst"
    cfg['cymbal']['sample'] = n[0].to_sym

# set drum "on" status based on the button state
  when "kick"
    cfg['kick']['on'] = n[0]==1.0
  when "snare"
    cfg['snare']['on'] = n[0]==1.0
  when "cymbal"
    cfg['cymbal']['on'] = n[0]==1.0
    
    #set amp
  when "bass_amp"
    cfg['bass']['amp'] = n[0]
  when "chord_amp"
    cfg['chord']['amp'] = n[0]
    
  when "kick_amp"
    cfg['kick']['amp'] = n[0]
  when "snare_amp"
    cfg['snare']['amp'] = n[0]
  when "cymbal_amp"
    cfg['cymbal']['amp'] = n[0]
    
    # save beat states
  when "kick_beats"
    cfg['kick']['beats'][token[2].to_i] = n[0].to_i
  when "snare_beats"
    cfg['snare']['beats'][token[2].to_i] = n[0].to_i
  when "cymbal_beats"
    cfg['cymbal']['beats'][token[2].to_i] = n[0].to_i
    
    # save mode and scale
  when "mode"
    cfg['mode'] = n[0].to_i
  when "scale"
    cfg['scale'] = n[0].to_sym
    the_scale = cfg['scale']
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
    pattern = cfg['pattern']
    pattern_mode = cfg['pattern_mode']
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
          gl_osc_ctrl("/bass_points", tonic_names)
          gl_osc_ctrl("/chord_points", tonic_names)
          
          bass_points_pos = []
          tonics_pattern = []
          chords_pattern = []
          tonics.length.times do |i|
            pos = gl_dist_pos i, tonics.length, 16
            tonics_pattern.push pos
            chords_pattern.push pos
            bass_points_pos.push pos
            bass_points_pos.push 0 #arr vertical pos for osc
          end
          gl_osc_ctrl("/bass_points_pos", *bass_points_pos)
          gl_osc_ctrl("/chord_points_pos", *bass_points_pos)
          gl_osc_ctrl("/scale_match", (gl_notes_in_scale tonics, cfg['scale'], tonics[0]) ? 1 : 0)
      end
    end
    when 1
      use_synth :piano
      play note
    end
  end
end
# END MIDI MESSAGE MONITORING LOOP
