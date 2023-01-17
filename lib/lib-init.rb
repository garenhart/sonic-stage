#######################
# lib-init.rb
# initialization/configuration library
# author: Garen H.
#######################

define :parse_addr do |path|
  e = get_event(path).to_s
  v = e.split(",")[6]
  if v != nil
    return v[3..-2].split("/")
  else
    return ["error"]
  end
end

# get the sample group name from a sample name (first substring before "_")
define :sample_group do |s|
  s.split("_").first
end

# Time State drum beats
define :init_time_state do |cfg|
  set :cymbal, cfg['cymbal']['beats']
  set :snare, cfg['snare']['beats']
  set :kick, cfg['kick']['beats']

  set :cymbal_inst, cfg['cymbal']['sample']
  set :snare_inst, cfg['snare']['sample']
  set :kick_inst, cfg['kick']['sample']
end

define :reset_tonics do |cfg|
  cfg['tonics'] = []
  cfg['bass']['pattern'] = []
  cfg['chords']['pattern'] = []
end

  