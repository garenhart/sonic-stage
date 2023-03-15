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

# Time State chord
define :init_time_state_chord do |cfg|
  set :chord_state, cfg['chord']
end

# Time State bass
define :init_time_state_bass do |cfg|
  set :bass_state, cfg['bass']
  puts "BASS SET", get(:bass_state)
end

# Time State drums
define :init_time_state_drums do |cfg|
  set :drums, cfg['drums']
end

# Time State
define :init_time_state do |cfg|
  init_time_state_chord cfg
  init_time_state_bass cfg
  init_time_state_drums cfg
end

define :reset_tonics do |cfg|
  cfg['bass']['tonics'] = []
  cfg['bass']['pattern'] = []
  cfg['chord']['tonics'] = []
  cfg['chord']['pattern'] = []
end

define :add_tonic do |cfg, tonic| 
  cfg['bass']['tonics'] << tonic
  cfg['chord']['tonics'] << tonic  
end

define :init_bass_pattern do |cfg|
  cfg['bass']['pattern'] = []
  cfg['bass']['tonics'].length.times do |i|
    pos = dist_pos i, cfg['bass']['tonics'].length, 16
    cfg['bass']['pattern'].push pos
  end
  init_time_state_bass cfg if get(:bass_auto)
end

define :init_chord_pattern do |cfg|
  cfg['chord']['pattern'] = []
  cfg['chord']['tonics'].length.times do |i|
    pos = dist_pos i, cfg['chord']['tonics'].length, 16
    cfg['chord']['pattern'].push pos
  end
  init_time_state_chord cfg if get(:chord_auto)    
end

# sets specific bass configuration component
define :init_bass_component do |cfg, c, v|
  cfg['bass'][c] = v
  init_time_state_bass cfg if get(:bass_auto)
end

# sets specific chord configuration component
define :init_chord_component do |cfg, c, v|
  cfg['chord'][c] = v
  init_time_state_chord cfg if get(:chord_auto)
end

# sets specific drum configuration component
define :init_drum_component do |cfg, d, c, v|
  cfg['drums'][d][c] = v
  init_time_state_drums cfg if get(:drums_auto)
end

# sets specified drum beat
define :init_drum_beat do |cfg, d, b, v|
  cfg['drums'][d]['beats'][b] = v  
  init_time_state_drums cfg if get(:drums_auto)
end