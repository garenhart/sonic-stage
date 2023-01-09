#######################
# lib-osc.rb
# osc library
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

# populates osc variable target with the list of SPi sample groups
define :populate_sample_groups do |target|
  return if target==nil
  sg = sample_groups
  sg_str = []
  # convert to array of strings
  for n in sg
    sg_str.push n.to_s
  end
  osc target, sg_str.to_s
end

# populates osc variable target with the list of SPi sample names
# for the specified sample group sg
define :populate_samples do |target, sg|
  puts "pop", target, sg
  return if target==nil or sg==nil
  sn = sample_names(sg)
  sn_str = "{"
  # convert to array of strings
  for n in sn
    sn_str += ", " if sn_str.length > 2
    sn_str += "\"" + n.to_s + "\": \"" + n.to_s + "\""
  end
  sn_str += "}"
  osc_ctrl target, sn_str
end

# directs osc message to open stage control
define :osc_ctrl do |path, *args|
  ip = "127.0.0.1"
  port =  7777 # make sure to match Open Stage Control's osc-port value

  osc_send ip, port, path, *args
end

define :osc_ctrl_inactive do |path, arg1, arg2=nil|
  ip = "127.0.0.1"
  port =  7777 # make sure to match Open Stage Control's osc-port value

  if arg2==nil
    osc_send ip, port, path, arg1
  else
    osc_send ip, port, path, arg1, arg2
  end
end
