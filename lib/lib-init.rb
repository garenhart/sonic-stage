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

define :add_tonic_bass do |cfg, tonic, beat| 
  cfg['bass']['tonics'] << tonic
  cfg['bass']['pattern'] << beat
  update_osc_bass_points cfg
  init_time_state_bass cfg if get(:bass_auto)
end

define :add_tonic_chord do |cfg, tonic, beat| 
  cfg['chord']['tonics'] << tonic
  cfg['chord']['pattern'] << beat
  update_osc_chord_points cfg
  init_time_state_chord cfg if get(:chord_auto)
end

# define :init_bass_pattern do |cfg|
#   cfg['bass']['pattern'] = []
#   cfg['bass']['tonics'].length.times do |i|
#     pos = dist_pos i, cfg['bass']['tonics'].length, cfg['bass']['count'] || 16
#     cfg['bass']['pattern'].push pos
#   end
#   update_osc_bass_points cfg
#   init_time_state_bass cfg if get(:bass_auto)
# end

define :delete_bass_pattern do |cfg, points|
  if ((points == nil) || (points.length == 0))
    cfg['bass']['pattern'] = []
    cfg['bass']['tonics'] = []
  else 
    # sort points in descending order
    points.sort! {|x,y| y <=> x}    
    points.each do |p|
      cfg['bass']['pattern'].delete_at(p)
      cfg['bass']['tonics'].delete_at(p)
    end
  end
  update_osc_bass_points cfg
  init_time_state_bass cfg if get(:bass_auto)
end

# define :init_chord_pattern do |cfg|
#   cfg['chord']['pattern'] = []
#   cfg['chord']['tonics'].length.times do |i|
#     pos = dist_pos i, cfg['chord']['tonics'].length, cfg['chord']['count'] || 16
#     cfg['chord']['pattern'].push pos
#   end
#   update_osc_chord_points cfg
#   init_time_state_chord cfg if get(:chord_auto)   
# end

define :delete_chord_pattern do |cfg, points|
  if ((points == nil) || (points.length == 0))
    cfg['chord']['pattern'] = []
    cfg['chord']['tonics'] = []
  else
    # sort points in descending order
    points.sort! {|x,y| y <=> x}      
    points.each do |p|
      cfg['chord']['pattern'].delete_at(p)
      cfg['chord']['tonics'].delete_at(p)      
    end
  end
  update_osc_chord_points cfg 
  init_time_state_chord cfg if get(:chord_auto)
end

# sets specific bass configuration component
define :init_bass_component do |cfg, c, v|
  cfg['bass'][c] = v
  init_time_state_bass cfg if get(:bass_auto)
  osc_ctrl "/bass_fav", bass_fav?(cfg, cfg['bass']['synth']) ? 1 : 0 if c == 'synth'
end

# sets specific chord configuration component
define :init_chord_component do |cfg, c, v|
  cfg['chord'][c] = v
  init_time_state_chord cfg if get(:chord_auto)
  osc_ctrl "/chord_fav", chord_fav?(cfg, cfg['chord']['synth']) ? 1 : 0 if c == 'synth'
end

# sets specific drum configuration component
define :init_drum_component do |cfg, d, c, v|
  cfg['drums'][d][c] = v
  init_time_state_drums cfg if get(:drums_auto)
  (osc_ctrl "/#{d}_fav", drum_fav?(cfg, d, v) ? 1 : 0) if c == 'sample'
end

# sets specified drum beat
define :init_drum_beat do |cfg, d, b, v|
  cfg['drums'][d]['beats'][b] = v  
  init_time_state_drums cfg if get(:drums_auto)
end

# updates drum beats for a specific drum using new beat_count
# appends  "0" chars to the end of the beat string
# or removes chars from the end of the beat string
define :update_drum_component_beats do |cfg, d, new_beat_count|
  old_beat_count = cfg['drums'][d]['beats'].length
  puts "length: #{old_beat_count}"
  if new_beat_count > old_beat_count
    (new_beat_count - old_beat_count).times do
      cfg['drums'][d]['beats'] << "0"
    end
  elsif new_beat_count < old_beat_count
    # remove trailing chars
    cfg['drums'][d]['beats'] = cfg['drums'][d]['beats'][0..(new_beat_count-1)]  
  end
end

define :update_drum_beats do |cfg, new_beat_count|
  cfg['drums']['count'] = new_beat_count
  update_drum_component_beats cfg, 'cymbal', new_beat_count
  update_drum_component_beats cfg, 'snare', new_beat_count
  update_drum_component_beats cfg, 'kick', new_beat_count  
  init_time_state_drums cfg if get(:drums_auto)
end

define :update_bass_count do |cfg, new_count|
# if new_count < cfg['bass']['count']
# iterate backwards through the pattern
# and delete any points that are >= new_count
# together with the corresponding tonic
  if new_count < cfg['bass']['count']
    cfg['bass']['pattern'].reverse_each do |p|
      if p >= new_count
        i = cfg['bass']['pattern'].index(p)
        puts "deleting #{p} at #{i}"
        cfg['bass']['pattern'].delete_at(i)
        cfg['bass']['tonics'].delete_at(i)
      end
      puts "pattern: #{cfg['bass']['pattern']}"
      puts "tonics: #{cfg['bass']['tonics']}"   
    end
  end

  cfg['bass']['count'] = new_count
  update_osc_bass_points cfg
  init_time_state_bass cfg if get(:bass_auto)
end

define :clone_bass_pattern do |cfg|
  # clone the bass pattern and tonics and concatenate to the end
  # of the existing pattern and tonics, then update the osc widget
  # if the pattern is empty, then do nothing
  if cfg['bass']['pattern'].length > 0
    # shift the pattern to the right by the "count" value
    # and concatenate to the existing pattern
    cfg['bass']['pattern'] += shift_pattern cfg['bass']['pattern'], cfg['bass']['count']
    cfg['bass']['tonics'] += cfg['bass']['tonics']
    cfg['bass']['count'] *= 2 # double the count
    update_osc_bass_points cfg
    init_time_state_bass cfg if get(:bass_auto)
  end
end

define :update_chord_count do |cfg, new_count|
  # if new_count < cfg['chord']['count']
  # iterate backwards through the pattern
  # and delete any points that are >= new_count
  # together with the corresponding tonic
  if new_count < cfg['chord']['count']
    cfg['chord']['pattern'].reverse_each do |p|
      if p >= new_count
        i = cfg['chord']['pattern'].index(p)
        puts "deleting #{p} at #{i}"
        cfg['chord']['pattern'].delete_at(i)
        cfg['chord']['tonics'].delete_at(i)
      end
      puts "pattern: #{cfg['chord']['pattern']}"
      puts "tonics: #{cfg['chord']['tonics']}"   
    end
  end

  cfg['chord']['count'] = new_count
  update_osc_chord_points cfg
  init_time_state_chord cfg if get(:chord_auto)
end

  
define :clone_chord_pattern do |cfg|
  # clone the chord pattern and tonics and concatenate to the end
  # of the existing pattern and tonics, then update the osc widget
  # if the pattern is empty, then do nothing
  if cfg['chord']['pattern'].length > 0
    # shift the pattern to the right by the "count" value
    # and concatenate to the existing pattern
    cfg['chord']['pattern'] += shift_pattern cfg['chord']['pattern'], cfg['chord']['count']
    cfg['chord']['tonics'] += cfg['chord']['tonics']
    cfg['chord']['count'] *= 2 # double the count
    update_osc_chord_points cfg
    init_time_state_chord cfg if get(:chord_auto)
  end
end

define :clone_drums_beats do |cfg|
  # clone the drum beats
  cfg['drums']['count'] *= 2 # double the count
  osc_ctrl "/beat_pt_count", cfg['drums']['count']
  clone_drum_beats cfg, 'cymbal'
  clone_drum_beats cfg, 'snare'
  clone_drum_beats cfg, 'kick'
end

define :clone_drum_beats do |cfg, d|
  # clone the drum beats and concatenate to the end
  # of the existing beats, then update the osc widget
  # if the beats are empty, then do nothing
  if cfg['drums'][d]['beats'].length > 0
    cfg['drums'][d]['beats'] += cfg['drums'][d]['beats']
    osc_ctrl "/#{d}_beats_v", cfg['drums'][d]['beats']
    init_time_state_drums cfg if get(:drums_auto)
  end
end

define :shift_pattern do |p, n|
  # shift the pattern to the right by n
  # and return the shifted pattern
  p.map {|x| x + n}
end

define :cfg_inst_root do |cfg, inst|
  return (inst == 'kick' || inst == 'snare' || inst == 'cymbal') ? cfg['drums'][inst] : cfg[inst]
end