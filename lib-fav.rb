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