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
end
end