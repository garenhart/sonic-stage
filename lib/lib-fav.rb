##################################################
# lib-fav.rb
# favorite instruments (samples/synths) library
# author: Garen H.
##################################################

define :drum_fav? do |cfg, d, v|
    cfg['drums'][d]['fav'].include?(v.to_s) if cfg['drums'][d]['fav']
end 

define :add_fav_drum do |cfg, d|
    # add 'fav' key to the drums hash if it doesn't exist
    cfg['drums'][d]['fav'] = [] unless cfg['drums'][d]['fav']    

    # add current selection to the favorites list
    cfg['drums'][d]['fav'] << cfg['drums'][d]['sample'].to_s unless drum_fav? cfg, d, cfg['drums'][d]['sample']
end
  
define :remove_fav_drum do |cfg, d|
    # remove current selection from the favorites list if it exists
    cfg['drums'][d]['fav'].delete(cfg['drums'][d]['sample'].to_s)
end

define :update_fav_drums do |cfg, d, add|
    # update the favorites list
    if add == 1.0
      add_fav_drum cfg, d
    else
      remove_fav_drum cfg, d
    end    
end

define :solo_fav? do |cfg, v|
    cfg['solo']['fav'].include?(v.to_s) if cfg['solo']['fav']
end

define :add_fav do |cfg|
    # add 'fav' key to the samples hash if it doesn't exist
    cfg['solo']['fav'] = [] unless cfg['solo']['fav']

    # add current selection to the favorites list
    cfg['solo']['fav'] << cfg['solo']['inst'].to_s unless solo_fav? cfg, cfg['solo']['inst']
    cfg['solo']['fav'].uniq!
end

define :remove_fav do |cfg|
    # remove current selection from the favorites list if it exists
    cfg['solo']['fav'].delete(cfg['solo']['inst'].to_s)
end

define :update_fav do |cfg, add|
    # update the favorites list
    if add == 1.0
      add_fav cfg
    else
      remove_fav cfg
    end
    init_osc_synths_fav cfg
end

define :chord_fav? do |cfg, v|
    cfg['chord']['fav'].include?(v.to_s) if cfg['chord']['fav']
end

define :add_fav_chord do |cfg|
    # add 'fav' key to the chord hash if it doesn't exist
    cfg['chord']['fav'] = [] unless cfg['chord']['fav']

    # add current selection to the favorites list
    cfg['chord']['fav'] << cfg['chord']['synth'].to_s unless chord_fav? cfg, cfg['chord']['synth']
end

define :remove_fav_chord do |cfg|
    # remove current selection from the favorites list if it exists
    cfg['chord']['fav'].delete(cfg['chord']['synth'].to_s)
end

define :update_fav_chord do |cfg, add|
    # update the favorites list
    if add == 1.0
      add_fav_chord cfg
    else
      remove_fav_chord cfg
    end
    init_osc_synths_fav_chord cfg
end

define :bass_fav? do |cfg, v|
  cfg['bass']['fav'].include?(v.to_s) if cfg['bass']['fav']
end

define :add_fav_bass do |cfg|
  # add 'fav' key to the bass hash if it doesn't exist
  cfg['bass']['fav'] = [] unless cfg['bass']['fav']

  # add current selection to the favorites list
  cfg['bass']['fav'] << cfg['bass']['synth'].to_s unless bass_fav? cfg, cfg['bass']['synth']
end

define :remove_fav_bass do |cfg|
  # remove current selection from the favorites list if it exists
  cfg['bass']['fav'].delete(cfg['bass']['synth'].to_s)
end

define :update_fav_bass do |cfg, add|
  # update the favorites list
  if add == 1.0
    add_fav_bass cfg
  else
    remove_fav_bass cfg
  end
  init_osc_synths_fav_bass cfg
end

# returns previous favorite instrument if it exists
define :prev_fav do |cfg, inst|
  if (inst == 'kick' || inst == 'snare' || inst == 'cymbal')
    cfg_root = cfg['drums'][inst]
    cur_inst = cfg_root['sample']
  else
    cfg_root = cfg[inst]
    cur_inst = (inst == 'solo') ? cfg_root['inst'] : cfg_root['synth']        
  end
  if cfg_root['fav']
    return prev_element(cfg_root['fav'], cur_inst.to_s)
  end
end

# returns next favorite instrument if it exists
define :next_fav do |cfg, inst|
  if (inst == 'kick' || inst == 'snare' || inst == 'cymbal')
    cfg_root = cfg['drums'][inst]
    cur_inst = cfg_root['sample']
  else
    cfg_root = cfg[inst]    
    cur_inst = (inst == 'solo') ? cfg_root['inst'] : cfg_root['synth']        
  end
  if cfg_root['fav']
    return next_element(cfg_root['fav'], cur_inst.to_s)
  end
end
