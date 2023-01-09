######################################
# osc_monitor.rb
# monitor/player part (Sonic Pi)
# no name yet for this project (Sonic Pi - Open Stage Control - Processing)
# author: Garen H.
######################################

use_debug false

#load libraries
require 'date'

eval_file get(:sp_path)+"lib/lib-io.rb"
eval_file get(:sp_path)+"lib/lib-init.rb"
eval_file get(:sp_path)+"lib/lib-chord-gen.rb"
eval_file get(:sp_path)+"lib/lib-osc-animation.rb"
eval_file get(:sp_path)+"lib/lib-play.rb"
eval_file get(:sp_path)+"lib/lib-osc.rb"
eval_file get(:sp_path)+"lib/lib-dyn-live_loop.rb"
#require get(:sp_path)+"lib/modes.rb" # Load extra scales and chords from separate file
#ModeScales = Modes.scales

# generic midi definitions
midi_in = "/midi:nanokey*/" # Korg nanoKey
# midi_in = "/midi*midi*/" # Komplete Kontrol M32
midi_daw = "/midi*m_daw*/" # Komplete Kontrol M32 
#######

# configuration folder path
configPath = get(:sp_path) + "live-impro\\sonic-pi-open-stage-control\\config\\" #path for config files
cfg_def = "default.json"
cfgFile = configPath + cfg_def
# deserialize JSON file into cfg hash
cfg = readJSON(cfgFile)
osc_ctrl "/cfg_file", cfg_def # init the osc control

puts "cfg", cfg

# Open Stage Control config
set :ctrl_ip, "127.0.0.1"
set :ctrl_port, 7777 # make sure to match Open Stage Control's osc-port value
# Processing config
set :anim_ip, "127.0.0.1"
set :anim_port, 8000 # make sure to match Processing osc-port value

# use_random_seed 31
# prog = [{tonic: :D, type: 'm7-5', invert: -1}, {tonic: :G, type: '7', invert: -1},{tonic: :C, type: 'mM7', invert: 1}]

init_tonics cfg
init_controls cfg
init_time_state cfg
# ---

# END DRUM CONFIG

# DRUM LOOPS
with_fx :reverb, room: 0.8, mix: 0.5 do |r|
  use_osc get(:anim_ip), get(:anim_port)
  live_loop :drum_kick do
    play_drum "kick", **cfg
  end
  
  live_loop :drum_snare do
    play_drum "snare", **cfg
  end
  
  live_loop :drum_cymbal do
    play_drum "cymbal", **cfg
  end
end
# END DRUM LOOPS

# CHORD LOOP
with_fx :reverb, room: 0.8, mix: 0.6 do |r|
  live_loop :chord do
    use_real_time
    use_bpm cfg['tempo']
    use_synth (cfg['chords']['synth']).to_sym
    sync :tick
    play_chords cfg
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
    play_bass cfg
  end
end
#END BASS LOOP

# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
  use_osc get(:ctrl_ip), get(:ctrl_port)
  addr = "/osc:#{get(:ctrl_ip)}:#{get(:ctrl_port)}/**"
  n = sync addr
  token = parse_addr addr
  
  case token[1]
  when "cfg_file"
    cfgFile = n[0]
    # deserialize JSON file into cfg hash
    cfg = readJSON(cfgFile)
    init_controls(cfg)
    
  when "save"
    # cfgFileNew = suffix_filename(cfgFile, DateTime.now.strftime("%m-%d-%y-%k%M%S"))
    # serialize cfg hash into JSON file
    write_unique_JSON(cfgFile, cfg)
    puts cfgFile
    
  when "tempo"
    cfg['tempo'] = n[0].to_i
    
  when "pattern"
    cfg['pattern'] = n[0].to_i
    
  when "pattern_mode"
    cfg['pattern_mode'] = n[0].to_i
    if n[0] == 1.0
      init_tonics cfg
    end
    
  when "switch_loop"
    cfg['loop_mode'] = n[0].to_i
    cfg['pattern_mode'] = 0 if n[0].to_i > 0
    
  when "bass_inst"
    cfg['bass']['synth'] = n[0].to_sym
    
  when "bass_line"
    bass_points_pos = []
    cfg['bass']['pattern'] = []
    n.length.times do |i|
      val = n[i].round
      cfg['bass']['pattern'].push val if i.even? # we only need X coord.
      bass_points_pos.push val
    end
    osc "/bass_points_pos", *bass_points_pos # send back rounded positions to imitate "snap to grid"
    
  when "chord_inst"
    cfg['chords']['synth'] = n[0].to_sym
    
  when "chord_line"
    chord_points_pos = []
    cfg['chords']['pattern'] = []
    n.length.times do |i|
      val = n[i].round
      cfg['chords']['pattern'].push val if i.even? # we only need X coord.
      chord_points_pos.push val
    end
    osc "/chord_points_pos", chord_points_pos.to_s # send back rounded positions to imitate "snap to grid"
    
  when "chord_type"
    cfg['chords']['type'] = n[0].to_i
    puts "TYPE", cfg['chords']['type']

  when "dropdown_drum_tempo_factor" # update Time State
    cfg['drum_tempo_factor'] = n[0].to_i
    
  when "drums" # update Time State beats
    if n[0] == 0.0
      init_time_state cfg
    end

  when "kick_inst_groups"
    puts "KICK_INST", n[0].to_sym
    populate_samples "/kick_inst_v", n[0].to_sym
  when "kick_inst"
    cfg['kick']['sample'] = n[0].to_sym
  when "snare_inst_groups"
    populate_samples "/snare_inst_v", n[0].to_sym
  when "snare_inst"
    cfg['snare']['sample'] = n[0].to_sym
  when "cymbal_inst_groups"
    populate_samples "/cymbal_inst_v", n[0].to_sym
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
    cfg['chords']['amp'] = n[0]
    
  when "kick_amp"
    cfg['kick']['amp'] = n[0]
  when "snare_amp"
    cfg['snare']['amp'] = n[0]
  when "cymbal_amp"
    cfg['cymbal']['amp'] = n[0]
    
    # save beat states
  when "kick_beats"
    cfg['kick']['beats'][token[2].to_i] = n[0].to_i.to_s
  when "snare_beats"
    cfg['snare']['beats'][token[2].to_i] = n[0].to_i.to_s
  when "cymbal_beats"
    cfg['cymbal']['beats'][token[2].to_i] = n[0].to_i.to_s
    
    # save mode and scale
  when "mode"
    cfg['mode'] = n[0].to_i
  when "scale"
    cfg['scale'] = n[0].to_sym
    the_scale = cfg['scale']
    puts "SSSSSSSSSSSSSSSSS", the_scale
    osc "/scale_match", (notes_in_scale cfg['tonics'], the_scale, cfg['tonics'][0]) ? 1 : 0
    init_keyboard(cfg['tonics'][0], the_scale)
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
    pattern = cfg['pattern']
    pattern_mode = cfg['pattern_mode']
    case cfg['loop_mode']
    when 0
      case pattern
      when 1
        if pattern_mode == 1
          use_synth :piano
          play note
          cfg['tonics'].push note
          tonic_names = notes_to_names(cfg['tonics']).to_s
          puts "TONICS", tonic_names
          osc_ctrl("/bass_points", tonic_names)
          osc_ctrl("/chord_points", tonic_names)
          
          bass_points_pos = []
          cfg['bass']['pattern'] = []
          cfg['chords']['pattern'] = []
          cfg['tonics'].length.times do |i|
            pos = dist_pos i, cfg['tonics'].length, 16
            cfg['bass']['pattern'].push pos
            cfg['chords']['pattern'].push pos
            bass_points_pos.push pos
            bass_points_pos.push 0 #arr vertical pos for osc
          end
          osc_ctrl("/bass_points_pos", *bass_points_pos)
          osc_ctrl("/chord_points_pos", *bass_points_pos)
          osc_ctrl("/scale_match", (notes_in_scale cfg['tonics'], cfg['scale'], cfg['tonics'][0]) ? 1 : 0)
      end
    end
    when 1
      use_synth :piano
      play note
    end
  end
end
# END MIDI MESSAGE MONITORING LOOP
