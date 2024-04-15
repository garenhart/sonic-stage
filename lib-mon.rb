#######################
# lib-mon.rb
# fx library
# author: Garen H.
#######################

define :drum_mon do |token, inst, n, cfg|
  case token[1]  
  when "#{inst}_inst_groups"
    init_osc_samples "/#{inst}_inst_v", n[0].to_sym, cfg
  when "#{inst}_inst"
    init_drum_component cfg, inst, "sample", n[0].to_sym
  when "#{inst}_pitch_shift"
    init_drum_component cfg, inst, "pitch_shift", n[0].to_i
  when "#{inst}_fav"
    update_fav_drums cfg, inst, n[0]
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
  else
    fx_mon token, inst, n, cfg
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