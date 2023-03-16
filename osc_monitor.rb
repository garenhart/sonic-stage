######################################
# osc_monitor.rb
# monitor/player part (Sonic Pi)
# no name yet for this project (Sonic Pi - Open Stage Control - Processing)
# author: Garen H.
######################################

use_debug false

#load libraries
require 'date'

eval_file get(:sp_path)+"lib/lib-util.rb"
eval_file get(:sp_path)+"lib/lib-io.rb"
eval_file get(:sp_path)+"lib/lib-init.rb"
eval_file get(:sp_path)+"lib/lib-chord-gen.rb"
eval_file get(:sp_path)+"lib/lib-osc-animation.rb"
eval_file get(:sp_path)+"lib/lib-play.rb"
eval_file get(:sp_path)+"lib/lib-osc.rb"
eval_file get(:sp_path)+"lib/lib-dyn-live_loop.rb"
#require get(:sp_path)+"lib/modes.rb" # Load extra scales and chord from separate file
#ModeScales = Modes.scales

# generic midi definitions
midi_in = "/midi:nanokey*/" # Korg nanoKey
# midi_in = "/midi*midi*/" # Komplete Kontrol M32
midi_daw = "/midi*m_daw*/" # Komplete Kontrol M32 
#######

# Open Stage Control config
set :ctrl_ip, "127.0.0.1"
set :ctrl_port, 7777 # make sure to match Open Stage Control's osc-port value
# Processing config
set :anim_ip, "127.0.0.1"
set :anim_port, 8000 # make sure to match Processing osc-port value

set :drums_auto, true
set :bass_auto, true
set :chord_auto, true

set :bass_rec, false
set :chord_rec, false

puts "CTRL", :ctrl_ip, :ctrl_port
# configuration folder path
configPath = get(:sp_path) + "live-impro\\sonic-pi-open-stage-control\\config\\" #path for config files
cfg_def = "default.json"
cfgFile = configPath + cfg_def
# deserialize JSON file into cfg hash
cfg = readJSON(cfgFile)
osc_ctrl "/open", cfg_def # set the osc control file name

puts "cfg", cfg

# use_random_seed 31
# prog = [{tonic: :D, type: 'm7-5', invert: -1}, {tonic: :G, type: '7', invert: -1},{tonic: :C, type: 'mM7', invert: 1}]

init_osc_controls cfg, true
init_time_state cfg
# ---

# DRUM LOOPS
with_fx :reverb, room: 0.8, mix: 0.5 do |r|
#  use_osc get(:anim_ip), get(:anim_port)
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
    play_chords **cfg
  end
end
#END CHORD LOOP

# BASS LOOP
with_fx :reverb, room: 0.6, mix: 0.4 do |r|
#  use_osc get(:anim_ip), get(:anim_port)
  live_loop :bass do
    play_bass **cfg
  end
end
#END BASS LOOP

# CUE LOOP (MUST BE LAST)
live_loop :the_cue do
  play_cue **cfg
end

# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
#  use_osc get(:ctrl_ip), get(:ctrl_port)
  addr = "/osc:#{get(:ctrl_ip)}:#{get(:ctrl_port)}/**"
  n = sync addr
  token = parse_addr addr
  
  case token[1]
  when "open"
    cfgFile = n[0]
    # deserialize JSON file into cfg hash
    cfg = readJSON(cfgFile)
    init_osc_controls(cfg)
    init_time_state_chord cfg if get(:chord_auto)
    init_time_state_bass cfg if get(:bass_auto)
    init_time_state_drums cfg if get(:drums_auto)
    
  when "save"
    # serialize cfg hash into JSON file
    new_name = write_unique_JSON(cfgFile, cfg)
    osc_ctrl "/NOTIFY", "clock", new_name + " saved"
    
  when "tempo"
    cfg['tempo'] = n[0].to_i
    
  when "pattern"
    cfg['pattern'] = n[0].to_i
    
  when "pattern_mode"
    cfg['pattern_mode'] = n[0].to_i
    if n[0] == 1.0
      reset_tonics cfg
    end
    
  when "switch_loop"
    cfg['loop_mode'] = n[0].to_i
    cfg['pattern_mode'] = 0 if n[0].to_i > 0

# chord section ==================================    
  when "chord_tempo_factor" # update Time State
    cfg['chord']['tempo_factor'] = n[0].to_i
    init_time_state_chord cfg if get(:chord_auto)

  when "chord_update" # update Time State
    init_time_state_chord cfg if n[0] == 0.0
    
  when "chord_auto"
    set :chord_auto, n[0].to_i == 1 ? true : false

  when "chord_inst"
    init_chord_component(cfg, "synth", n[0].to_sym)
    
  when "chord_type"
    init_chord_component(cfg, "type", n[0].to_i)    

  when "chord_line_updated"
    # add elements with even indices (0, 2, 4...) of array n to bass pattern
    # (we only need x coordinates), and convert to integer
    init_chord_component(cfg, "pattern", (n.select.with_index { |_, i| i.even? }).map { |x| x.to_i })

  when "chord_on"
    init_chord_component(cfg, "on", n[0]==1.0)
  
  when "chord_amp"
    init_chord_component(cfg, "amp", n[0])

  # bass section ===================================    
  when "bass_tempo_factor" # update Time State
    cfg['bass']['tempo_factor'] = n[0].to_i
    init_time_state_bass cfg if get(:bass_auto)

  when "bass_update" # update Time State
    init_time_state_bass cfg if n[0] == 0.0
    
  when "bass_auto"
    set :bass_auto, n[0].to_i == 1 ? true : false

  when "bass_inst"
    init_bass_component(cfg, 'synth', n[0].to_sym)
    
  when "bass_line_updated"
    # add elements with even indices (0, 2, 4...) of array n to bass pattern
    # (we only need x coordinates), and convert to integer
    init_bass_component(cfg, 'pattern', (n.select.with_index { |_, i| i.even? }).map { |x| x.to_i })

  when "bass_on"
    init_bass_component(cfg, 'on', n[0]==1.0)
    
  when "bass_amp"
    init_bass_component(cfg, 'amp', n[0])

  
  # drum section ==================================
  when "drum_tempo_factor" # update Time State
    cfg['drums']['tempo_factor'] = n[0].to_i
    init_time_state_drums cfg if get(:drums_auto)

  when "drums_update" # update Time State
    init_time_state_drums cfg if n[0] == 0.0
    
  when "drums_auto"
    set :drums_auto, n[0].to_i == 1 ? true : false

  # drum instruments
  when "kick_inst_groups"
    puts "KICK_INST", n[0].to_sym
    init_osc_samples "/kick_inst_v", n[0].to_sym
  when "kick_inst"
    init_drum_component cfg, "kick", "sample", n[0].to_sym
  when "snare_inst_groups"
    init_osc_samples "/snare_inst_v", n[0].to_sym
  when "snare_inst"
    init_drum_component cfg, "snare", "sample", n[0].to_sym
  when "cymbal_inst_groups"
    init_osc_samples "/cymbal_inst_v", n[0].to_sym
  when "cymbal_inst"
    init_drum_component cfg, "cymbal", "sample", n[0].to_sym
 
  when "cymbal_on"
    init_drum_component cfg, "cymbal", "on", n[0]==1.0
  when "snare_on"
    init_drum_component cfg, "snare", "on", n[0]==1.0
  when "kick_on"
    init_drum_component cfg, "kick", "on", n[0]==1.0

  # drum amps
  when "cymbal_amp"
    init_drum_component cfg, "cymbal", "amp", n[0]
  when "snare_amp"
    init_drum_component cfg, "snare", "amp", n[0]
  when "kick_amp"
    init_drum_component cfg, "kick", "amp", n[0]
   
  # drum beats
  when "kick_beats"
    init_drum_beat cfg, "kick", token[2].to_i, n[0].to_i.to_s
  when "snare_beats"
    init_drum_beat cfg, "snare", token[2].to_i, n[0].to_i.to_s
  when "cymbal_beats"
    init_drum_beat cfg, "cymbal", token[2].to_i, n[0].to_i.to_s
# end drum section ==================================

 # save mode and scale
  when "mode"
    cfg['mode'] = n[0].to_i
  when "scale"
    cfg['scale'] = n[0].to_sym
    puts "SSSSSSSSSSSSSSSSS", cfg['scale']
    update_scale_match cfg

  # recording
  when "bass_rec"
    set :bass_rec, n[0].to_i == 1 ? true : false

  when "chord_rec"
    set :chord_rec, n[0].to_i == 1 ? true : false    
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

    bass_rec = get(:bass_rec)
    chord_rec = get(:chord_rec) 
    
    if (bass_rec || chord_rec) # recording
      if (bass_rec)
          use_synth cfg['bass']['synth'].to_sym
          add_tonic_bass cfg, note
      end
      if (chord_rec)
          use_synth cfg['chord']['synth'].to_sym
          add_tonic_chord cfg, note
      end
    else # not recording
      use_synth :piano
    end   
    play note                
  end
end
# END MIDI MESSAGE MONITORING LOOP

