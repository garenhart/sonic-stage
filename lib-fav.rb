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
    cfg['fav'].include?(v.to_s) if cfg['fav']
end

define :add_fav do |cfg|
    # add 'fav' key to the samples hash if it doesn't exist
    cfg['fav'] = [] unless cfg['fav']

    # add current selection to the favorites list
    cfg['fav'] << cfg['solo_inst'].to_s unless solo_fav? cfg, cfg['solo_inst']
    cfg['fav'].uniq!
end

define :remove_fav do |cfg|
    # remove current selection from the favorites list if it exists
    cfg['fav'].delete(cfg['solo_inst'].to_s)
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
