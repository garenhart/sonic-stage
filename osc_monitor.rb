######################################
# osc_monitor.pi
# monitor/player part (Sonic Pi)
# no name yet for this project (Sonic Pi - Open Stage Control - Processing)
# author: Garen H.
######################################

use_debug false
use_midi_logging false
use_cue_logging false
use_osc_logging false
use_arg_checks false

# use_transpose 0 #add optional transpose manually

#load libraries
require 'date'

sp_path = get(:sp_path) # get Sonic Pi path
# construct path to sonic-stage-lib from ENV[HOME] variable
sp_lib_path = ENV['HOME'] + '/dev/sonic-pi-projects/sonic-stage-lib/'
eval_file sp_lib_path + 'lib-util.rb'
eval_file sp_lib_path + 'lib-io.rb'
eval_file sp_lib_path + 'lib-fav.rb'
eval_file sp_lib_path + 'lib-fx.rb'
eval_file sp_lib_path + 'lib-init.rb'
eval_file sp_lib_path + 'lib-osc-animation.rb'
eval_file sp_lib_path + 'lib-play.rb'
eval_file sp_lib_path + 'lib-osc.rb'
eval_file sp_lib_path + 'lib-dyn-live_loop.rb'
eval_file sp_lib_path + 'lib-chord-gen.rb'
eval_file sp_lib_path + 'lib-mon.rb'

#require get(:sp_path)+"sonic-stage-lib/modes.rb" # Load extra scales and chord from separate file
#ModeScales = Modes.scales

# generic midi definitions
midi_in = "/midi*/" # This one seems to work for most midi devices

# midi_in = "/midi:nanokey*/" # Korg nanoKey
# midi_in = "/midi*midi*/" # Komplete Kontrol M32
# midi_daw = "/midi*m_daw*/" # Komplete Kontrol M32 
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

bass_rec = false
chord_rec = false

puts "CTRL", :ctrl_ip, :ctrl_port
# configuration folder path
configPath = get(:sp_path) + "sonic-stage\\config\\" # path for config files
cfg_def = "_default.json"
cfgFile = configPath + cfg_def
# deserialize JSON file into cfg hash
cfg = initJSON(cfgFile)
osc_ctrl "/cfg_path", configPath # set the osc control path
osc_ctrl "/open", cfg_def # set the osc control file name

puts "cfg", cfg

# use_random_seed 31
# prog = [{tonic: :D, type: 'm7-5', invert: -1}, {tonic: :G, type: '7', invert: -1},{tonic: :C, type: 'mM7', invert: 1}]

# init osc controls twice to avoid blank instruments
init_osc_controls cfg, true
init_time_state cfg
# ---
sleep 1 # wait for init to finish

# set_audio_latency! -100 # set audio latency to -100ms

live_loop :drum_kick do
  play_drum "kick", cfg
end

live_loop :drum_snare do
  play_drum "snare", cfg
end

live_loop :drum_cymbal do
  play_drum "cymbal", cfg
end
# END DRUM LOOPS

live_loop :chord do
  play_chords cfg
end

live_loop :bass do
  play_bass cfg
end

with_effects fx_chain(cfg['solo']['fx']) do
  live_loop :midi_solo do
    # WARNING: use_real_time must be set to true for this to work
    # WARNING: moving following 4 lines to play_midi() causing
    # first note to be skipped when new file is opened (why?)
    use_real_time

    addr = midi_in + "note_on"
    note, vel = sync addr
    addr_data = parse_addr addr
    
    play_midi_solo cfg, addr_data, note, vel  if (cfg['solo']['on'] && !bass_rec && !chord_rec)
  end
end

with_effects fx_chain(cfg['bass']['fx']) do
  live_loop :midi_bass do
    # WARNING: use_real_time must be set to true for this to work
    # WARNING: moving following 4 lines to play_midi() causing
    # first note to be skipped when new file is opened (why?)
    use_real_time

    addr = midi_in + "note_on"
    note, vel = sync addr
    addr_data = parse_addr addr
    
    play_midi_bass bass_rec, cfg, addr_data, note, vel, get(:beat) + 1 if bass_rec

  end
end

with_effects fx_chain(cfg['chord']['fx']) do
  live_loop :midi_chord do
    # WARNING: use_real_time must be set to true for this to work
    # WARNING: moving following 4 lines to play_midi() causing
    # first note to be skipped when new file is opened (why?)
    use_real_time

    addr = midi_in + "note_on"
    note, vel = sync addr
    addr_data = parse_addr addr
    
    play_midi_chord chord_rec, cfg, addr_data, note, vel, get(:beat) + 1 if chord_rec
  end
end


# CUE LOOP (MUST BE LAST OF SYNC LOOPS!!!)
live_loop :the_cue do
  play_cue cfg
end

# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
#  use_osc get(:ctrl_ip), get(:ctrl_port)
  addr = "/osc:#{get(:ctrl_ip)}:#{get(:ctrl_port)}/**"
  n = sync addr
  token = parse_addr addr
 
  t = token[1].split("_")[0]
  if t == "kick"  || t == "snare" || t == "cymbal"
    puts "TOKEN========", t
    drum_mon token, t, n, cfg
  else
    case token[1]
    when "open"
      cfgFile = n[0]
      # deserialize JSON file into cfg hash
      data = initJSON(cfgFile)

      ca = get(:chord_auto)
      ba = get(:bass_auto)
      da = get(:drums_auto)

      # accept data only if all _auto states are true
      # or new "tempo" is the same as current tempo
      if (ca && ba && da) || (data['tempo'] == cfg['tempo'])
        cfg = data
        # init osc controls twice to avoid blank instruments
        init_osc_controls cfg
        init_osc_controls cfg

        init_time_state_chord cfg if get(:chord_auto)
        init_time_state_bass cfg if get(:bass_auto)
        init_time_state_drums cfg if get(:drums_auto)
      else
        osc_ctrl "/NOTIFY", "triangle-exclamation", "Tempo mismatch! Cannot load " + cfgFile
      end
      
    when "save"
      # serialize cfg hash into JSON file
      new_name = write_unique_JSON(cfgFile, cfg)
      osc_ctrl "/NOTIFY", "folder-plus", new_name + " saved"
      
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

    when "solo_inst"
      cfg['solo']['inst'] = n[0].to_sym
      osc_ctrl "/solo_fav", solo_fav?(cfg, cfg['solo']['inst']) ? 1 : 0

    when "solo_inst_prev"
      prev_f = prev_fav cfg, "solo"      
      cfg['solo']['inst'] = prev_f if prev_f
      osc_ctrl "/solo_inst", cfg['solo']['inst']

    when "solo_inst_next"
      next_f = next_fav cfg, "solo"
      cfg['solo']['inst'] = next_f if next_f            
      osc_ctrl "/solo_inst", cfg['solo']['inst']

    when "solo_on"
      cfg['solo']['on'] = n[0] == 1.0

    when "solo_fav"
      update_fav cfg, n[0]

    when "solo_fav_all"
      cfg['solo']['fav_all'] = n[0] == 1.0

    when "solo_env_adsr"
      cfg['solo']['adsr'] = n
 
    when "solo_fx1_fx"
      init_fx_component cfg, "solo", 0, 0, n[0]
      update_osc_fx_option_names "solo", n[0], 1

    when "solo_fx1_opt1_value"
      init_fx_component cfg, "solo", 0, 1, n

    when "solo_fx1_opt2_value"
      init_fx_component cfg, "solo", 0, 2, n

    when "solo_fx2_fx"
      init_fx_component cfg, "solo", 1, 0, n[0]
      update_osc_fx_option_names "solo", n[0], 2

    when "solo_fx2_opt1_value"
      init_fx_component cfg, "solo", 1, 1, n

    when "solo_fx2_opt2_value"
      init_fx_component cfg, "solo", 1, 2, n

  # chord section ==================================    
    when "chord_pt_count"
      update_chord_count cfg, n[0].to_i
    
    when "chord_dup_data"
      clone_chord_pattern cfg

    when "chord_tempo_factor" # update Time State
      cfg['chord']['tempo_factor'] = n[0].to_i
      init_time_state_chord cfg if get(:chord_auto)

    when "chord_update" # update Time State
      init_time_state_chord cfg if n[0] == 0.0
      
    when "chord_auto"
      set :chord_auto, n[0].to_i == 1 ? true : false

    when "chord_inst"
      init_chord_component(cfg, "synth", n[0].to_sym)

    when "chord_inst_prev"
      prev_f = prev_fav cfg, 'chord'      
      init_chord_component(cfg, 'synth', prev_f) if prev_f
      osc_ctrl "/chord_inst", cfg['chord']['synth']

    when "chord_inst_next"
      next_f = next_fav cfg, 'chord'
      init_chord_component(cfg, 'synth', next_f) if next_f
      osc_ctrl "/chord_inst", cfg['chord']['synth']

    when "chord_type"
      init_chord_component(cfg, "type", n[0].to_i)    

    when "chord_line_updated"
      # add elements with even indices (0, 2, 4...) of array n to bass pattern
      # (we only need x coordinates), and convert to integer
      init_chord_component(cfg, "pattern", (n.select.with_index { |_, i| i.even? }).map { |x| x.to_i })

    when "chord_on"
      init_chord_component(cfg, "on", n[0]==1.0)

    when "chord_fav"
      update_fav_chord cfg, n[0]

    when "chord_fav_all"
      cfg['chord']['fav_all'] = n[0] == 1.0

    when "chord_env_adsr"
      init_chord_component(cfg, 'adsr', n)      

    when "chord_fx1_fx"
      init_fx_component cfg, "chord", 0, 0, n[0]
      update_osc_fx_option_names "chord", n[0], 1

    when "chord_fx1_opt1_value"
      init_fx_component cfg, "chord", 0, 1, n

    when "chord_fx1_opt2_value"
      init_fx_component cfg, "chord", 0, 2, n

    when "chord_fx2_fx"
      init_fx_component cfg, "chord", 1, 0, n[0]
      update_osc_fx_option_names "chord", n[0], 2

    when "chord_fx2_opt1_value"
      init_fx_component cfg, "chord", 1, 1, n

    when "chord_fx2_opt2_value"
      init_fx_component cfg, "chord", 1, 2, n


    when "chord_amp"
      init_chord_component(cfg, "amp", n[0])
    
    when "chord_delete"
      # cast n array to array of integers
      n = n.map { |x| x.to_i }    
      delete_chord_pattern cfg, n

    # bass section ===================================    
    when "bass_pt_count"
      update_bass_count cfg, n[0].to_i

    when "bass_dup_data"
      clone_bass_pattern cfg

    when "bass_tempo_factor" # update Time State
      cfg['bass']['tempo_factor'] = n[0].to_i
      init_time_state_bass cfg if get(:bass_auto)

    when "bass_update" # update Time State
      init_time_state_bass cfg if n[0] == 0.0
      
    when "bass_auto"
      set :bass_auto, n[0].to_i == 1 ? true : false

    when "bass_inst"
      init_bass_component(cfg, 'synth', n[0].to_sym)

    when "bass_inst_prev"
      prev_f = prev_fav cfg, 'bass'      
      init_bass_component(cfg, 'synth', prev_f) if prev_f
      osc_ctrl "/bass_inst", cfg['bass']['synth']

    when "bass_inst_next"
      next_f = next_fav cfg, 'bass'
      init_bass_component(cfg, 'synth', next_f) if next_f
      osc_ctrl "/bass_inst", cfg['bass']['synth']
      
    when "bass_line_updated"
      # add elements with even indices (0, 2, 4...) of array n to bass pattern
      # (we only need x coordinates), and convert to integer
      init_bass_component(cfg, 'pattern', (n.select.with_index { |_, i| i.even? }).map { |x| x.to_i })

    when "bass_on"
      init_bass_component(cfg, 'on', n[0]==1.0)

    when "bass_fav"
      update_fav_bass cfg, n[0]

    when "bass_fav_all"
      cfg['bass']['fav_all'] = n[0] == 1.0

    when "bass_env_adsr"
      init_bass_component(cfg, 'adsr', n)

    when "bass_fx1_fx"
      init_fx_component cfg, "bass", 0, 0, n[0]
      update_osc_fx_option_names "bass", n[0], 1

    when "bass_fx1_opt1_value"
      init_fx_component cfg, "bass", 0, 1, n

    when "bass_fx1_opt2_value"
      init_fx_component cfg, "bass", 0, 2, n

    when "bass_fx2_fx"
      init_fx_component cfg, "bass", 1, 0, n[0]
      update_osc_fx_option_names "bass", n[0], 2

    when "bass_fx2_opt1_value"
      init_fx_component cfg, "bass", 1, 1, n

    when "bass_fx2_opt2_value"
      init_fx_component cfg, "bass", 1, 2, n


    when "bass_amp"
      init_bass_component(cfg, 'amp', n[0])

    when "bass_delete"
      # cast n array to array of integers
      n = n.map { |x| x.to_i }    
      delete_bass_pattern cfg, n
    
    # drum section ==================================
    when "beat_pt_count"
      update_drum_beats cfg, n[0].to_i

    when "drum_dup_data"
      clone_drums_beats cfg
      
    when "drum_tempo_factor" # update Time State
      cfg['drums']['tempo_factor'] = n[0].to_i
      init_time_state_drums cfg if get(:drums_auto)

    when "drums_update" # update Time State
      init_time_state_drums cfg if n[0] == 0.0
      
    when "drums_auto"
      set :drums_auto, n[0].to_i == 1 ? true : false

  # save mode and scale
    when "mode"
      cfg['mode'] = n[0].to_i
    when "scale"
      cfg['scale'] = n[0].to_sym
      puts "SSSSSSSSSSSSSSSSS", cfg['scale']
      update_scale_match cfg

    # recording
    when "bass_rec"
      bass_rec = n[0].to_i == 1 ? true : false

    when "chord_rec"
      chord_rec = n[0].to_i == 1 ? true : false    
    end
  end
end
# END OSC MESSAGE MONITORING LOOP
