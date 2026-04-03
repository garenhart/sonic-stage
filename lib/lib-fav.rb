##################################################
# lib-fav.rb
# favorite instruments (samples/synths) library
# author: Garen H.
##################################################

# Returns true if value v is in the favorites list for instrument inst
define :inst_fav? do |cfg, inst, v|
  root = cfg_inst_root(cfg, inst)
  root['fav'] && root['fav'].include?(v.to_s)
end

# Adds the current instrument/sample to the favorites list
define :add_fav_inst do |cfg, inst|
  root = cfg_inst_root(cfg, inst)
  root['fav'] ||= []
  cur = root[inst_name_key(inst)].to_s
  root['fav'] << cur unless root['fav'].include?(cur)
end

# Removes the current instrument/sample from the favorites list
define :remove_fav_inst do |cfg, inst|
  root = cfg_inst_root(cfg, inst)
  cur = root[inst_name_key(inst)].to_s
  root['fav'].delete(cur) if root['fav']
end

# Adds or removes from favorites based on add flag, then refreshes OSC dropdown
define :update_fav_inst do |cfg, inst, add|
  if add == 1.0
    add_fav_inst cfg, inst
  else
    remove_fav_inst cfg, inst
  end
  init_osc_synths_fav_inst cfg, inst unless is_drum?(inst)
end

# Returns previous favorite instrument if it exists
define :prev_fav do |cfg, inst|
  root = cfg_inst_root(cfg, inst)
  cur = root[inst_name_key(inst)].to_s
  prev_element(root['fav'], cur) if root['fav']
end

# Returns next favorite instrument if it exists
define :next_fav do |cfg, inst|
  root = cfg_inst_root(cfg, inst)
  cur = root[inst_name_key(inst)].to_s
  next_element(root['fav'], cur) if root['fav']
end
