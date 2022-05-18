#######################
# lib-osc.rb
# osc library
# gl_ prefix is used for methods to indicate "garen's library"
#     in absence of support for namespaces and classes 
# author: Garen H.
#######################

define :gl_parse_addr do |path|
    e = get_event(path).to_s
    v = e.split(",")[6]
    if v != nil
      return v[3..-2].split("/")
    else
      return ["error"]
    end
  end

define :gl_reset_keyboard do |tonic, mode|
  scale_notes = scale tonic, mode
  for note in 21..107
    osc "/keyboard_scale", note, (scale_notes.to_a.include? note) ? 1 : 0
  end
end

# populates osc variable target with the list of SPi sample names
# for the specified sample group sg
define :gl_populate_samples do |target, sg|
  return if target==nil or sg==nil
  sn = sample_names(sg)
  sn_osc = []
  for n in sn
    sn_osc.push n.to_s
  end
  osc target, sn_osc.to_s
end

define :gl_populate_drum_samples do
  #kick
  gl_populate_samples "/inst_kick", :bd
end