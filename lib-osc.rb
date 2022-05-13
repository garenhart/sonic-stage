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

