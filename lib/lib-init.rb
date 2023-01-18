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

define :add_tonic do |cfg, tonic| 
  cfg['tonics'] << tonic
#  cfg['tonics'].push note
end

define :init_bass_pattern do |cfg|
  cfg['bass']['pattern'] = []
  cfg['tonics'].length.times do |i|
    pos = dist_pos i, cfg['tonics'].length, 16
    cfg['bass']['pattern'].push [pos, cfg['tonics'][i]]
  end
end

define :init_chords_pattern do |cfg|
  cfg['chords']['pattern'] = []
  cfg['tonics'].length.times do |i|
    pos = dist_pos i, cfg['tonics'].length, 16
    cfg['chords']['pattern'].push [pos, cfg['tonics'][i]]
  end
end

