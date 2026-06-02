#######################
# lib-mon.rb
# OSC monitor library
# author: Garen H.
#######################

define :drum_mon do |token, inst, n, cfg|
  case token[1]  
    when "#{inst}_inst_groups"
      init_osc_samples "/#{inst}_inst_v", n[0].to_sym, cfg
    when "#{inst}_inst"
      init_drum_component cfg, inst, "sample", n[0].to_sym
    when "#{inst}_inst_prev"
      prev_f = prev_fav cfg, inst
      init_drum_component cfg, inst, "sample", prev_f if prev_f            
      osc_ctrl "/#{inst}_inst", (cfg['drums'][inst]['sample'])
    when "#{inst}_inst_next"
      next_f = next_fav cfg, inst
      init_drum_component cfg, inst, "sample", next_f if next_f      
      osc_ctrl "/#{inst}_inst", (cfg['drums'][inst]['sample'])   
    when "#{inst}_pitch_shift"
      init_drum_component cfg, inst, "pitch_shift", n[0].to_i
    when "#{inst}_fav"
      update_fav_inst cfg, inst, n[0]
    when "#{inst}_range"
      init_drum_component cfg, inst, "range", n
    when "#{inst}_random"
      init_drum_component cfg, inst, "random", n[0]==1.0
    when "#{inst}_reverse"
      init_drum_component cfg, inst, "reverse", n[0]==1.0
    when "#{inst}_on"
      init_drum_component cfg, inst, "on", n[0]==1.0
    when "#{inst}_amp"
      init_drum_component cfg, inst, "amp", n[0]
    when "#{inst}_beats"
      init_drum_beat cfg, inst, token[2].to_i, n[0].to_i.to_s
    when "#{inst}_reset_beats"
      cfg['drums'][inst]['beats'] = "0" * cfg['drums']['count']
      init_time_state_drums cfg
      osc_ctrl "/#{inst}_beats_v", cfg['drums'][inst]['beats']
    when "#{inst}_env_adsr"
      init_drum_component cfg, inst, "adsr", n
    else
      fx_mon token, inst, n, cfg
      init_time_state_drums cfg
  end
end

define :fx_mon do |token, inst, n, cfg|
  case token[1]
    when "#{inst}_fx1_fx"
      init_fx_component cfg, inst, 0, 0, n[0]
      update_osc_fx_option_names inst, n[0], 1
    when "#{inst}_fx1_opt1_value"
      init_fx_component cfg, inst, 0, 1, n
    when "#{inst}_fx1_opt2_value"
      init_fx_component cfg, inst, 0, 2, n
    when "#{inst}_fx2_fx"
      init_fx_component cfg, inst, 1, 0, n[0]
      update_osc_fx_option_names inst, n[0], 2
    when "#{inst}_fx2_opt1_value"
      init_fx_component cfg, inst, 1, 1, n
    when "#{inst}_fx2_opt2_value"
      init_fx_component cfg, inst, 1, 2, n
  end
end

define :handle_osc do |token, t, n, cfg, cfg_file|
  if is_drum?(t)
    drum_mon token, t, n, cfg
  elsif ["solo", "bass", "chord"].include?(t) && token[1].include?("_fx")
    fx_mon token, t, n, cfg
    init_time_state_bass cfg if t == "bass" && cfg['bass']['auto']
    init_time_state_chord cfg if t == "chord" && cfg['chord']['auto']
  else
    case token[1]
    when "save"
      new_name = write_unique_JSON(cfg_file, cfg)
      osc_ctrl "/NOTIFY", "folder-plus", new_name + " saved"

    when "tempo"
      cfg['tempo'] = n[0].to_i
      set :tempo, n[0].to_i

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
      osc_ctrl "/solo_fav", inst_fav?(cfg, 'solo', cfg['solo']['inst']) ? 1 : 0

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
      update_fav_inst cfg, 'solo', n[0]

    when "solo_fav_all"
      cfg['solo']['fav_all'] = n[0] == 1.0

    when "solo_env_adsr"
      cfg['solo']['adsr'] = n

  # chord section ==================================
    when "chord_pt_count"
      update_chord_count cfg, n[0].to_i

    when "chord_dup_data"
      clone_chord_pattern cfg

    when "chord_tempo_factor"
      cfg['chord']['tempo_factor'] = n[0].to_i
      init_time_state_chord cfg

    when "chord_auto"
      cfg['chord']['auto'] = n[0].to_i == 1 ? true : false

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
      init_chord_component(cfg, "pattern", (n.select.with_index { |_, i| i.even? }).map { |x| x.to_i })

    when "chord_on"
      init_chord_component(cfg, "on", n[0]==1.0)

    when "chord_fav"
      update_fav_inst cfg, 'chord', n[0]

    when "chord_fav_all"
      cfg['chord']['fav_all'] = n[0] == 1.0

    when "chord_env_adsr"
      init_chord_component(cfg, 'adsr', n)

    when "chord_amp"
      init_chord_component(cfg, "amp", n[0])

    when "chord_delete"
      n = n.map { |x| x.to_i }
      delete_chord_pattern cfg, n

  # bass section ===================================
    when "bass_pt_count"
      update_bass_count cfg, n[0].to_i

    when "bass_dup_data"
      clone_bass_pattern cfg

    when "bass_tempo_factor"
      cfg['bass']['tempo_factor'] = n[0].to_i
      init_time_state_bass cfg

    when "bass_auto"
      cfg['bass']['auto'] = n[0].to_i == 1 ? true : false

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
      init_bass_component(cfg, 'pattern', (n.select.with_index { |_, i| i.even? }).map { |x| x.to_i })

    when "bass_on"
      init_bass_component(cfg, 'on', n[0]==1.0)

    when "bass_fav"
      update_fav_inst cfg, 'bass', n[0]

    when "bass_fav_all"
      cfg['bass']['fav_all'] = n[0] == 1.0

    when "bass_env_adsr"
      init_bass_component(cfg, 'adsr', n)

    when "bass_amp"
      init_bass_component(cfg, 'amp', n[0])

    when "bass_delete"
      n = n.map { |x| x.to_i }
      delete_bass_pattern cfg, n

  # drum section ==================================
    when "beat_pt_count"
      update_drum_beats cfg, n[0].to_i

    when "drum_dup_data"
      clone_drums_beats cfg

    when "drum_tempo_factor"
      cfg['drums']['tempo_factor'] = n[0].to_i
      init_time_state_drums cfg

    when "drums_auto"
      cfg['drums']['auto'] = n[0].to_i == 1 ? true : false

  # mode and scale
    when "mode"
      cfg['mode'] = n[0].to_i
    when "scale"
      cfg['scale'] = n[0].to_sym
      update_scale_match cfg

  # recording
    when "bass_rec"
      set :bass_rec, n[0].to_i == 1 ? true : false

    when "chord_rec"
      set :chord_rec, n[0].to_i == 1 ? true : false
    end
  end
end