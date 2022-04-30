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
  