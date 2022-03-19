#######################
# Garen H.
# osc library
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
  