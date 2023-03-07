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

# Time State chords
define :init_time_state_chords do |cfg|
  set :chords, cfg['chords']
end

# Time State bass
define :init_time_state_bass do |cfg|
  set :bass, cfg['bass']
  puts "BASS SET", get(:bass)
end

# Time State drums
define :init_time_state_drums do |cfg|
  set :drums, cfg['drums']
end

# Time State
define :init_time_state do |cfg|
  init_time_state_chords cfg
  init_time_state_bass cfg
  init_time_state_drums cfg
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
    cfg['bass']['pattern'].push pos
  end
end

define :init_chords_pattern do |cfg|
  cfg['chords']['pattern'] = []
  cfg['tonics'].length.times do |i|
    pos = dist_pos i, cfg['tonics'].length, 16
    cfg['chords']['pattern'].push pos
  end
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