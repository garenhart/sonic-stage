#######################
# lib-util.rb
# utility library
# author: Garen H.
#######################

# 'pseudo'-evenly distributes 'count' positions within number of 'slots'
# returns distributed position for 'item_num' 
define :dist_pos do |item_num, count, slots| 
    pos = item_num * (slots / count) + 1
end

# Splits string 'str' into words based on pattern and capitalizes each word
define :split_and_capitalize do |str, pattern|
    str.split(pattern).map {|x| x.capitalize}.join(" ")
end

# Extracts substring between '[' and ']' from string 'str'
define :extract_between_brackets do |str|
    str[/\[(.*?)\]/m, 1]
end

# Returns time difference in milliseconds between two times
define :time_diff_ms do |start, finish|
    (finish - start) * 1000.0
end

# Returns the next element in the ring after 'element'
# Returns nil if ring is empty or element is not found
define :next_element do |ring, element|
    return nil if ring.empty?
    index = ring.index(element)
    return nil if index.nil?
    next_index = (index + 1) % ring.size
    return ring[next_index]
end

# Returns the previous element in the ring before 'element'
# Returns nil if ring is empty or element is not found
define :prev_element do |ring, element|
    return nil if ring.empty?
    index = ring.index(element)
    return nil if index.nil?
    prev_index = (index - 1) % ring.size
    return ring[prev_index]
end

# Returns true if inst is a drum component (kick, snare, cymbal)
define :is_drum? do |inst|
  inst == 'kick' || inst == 'snare' || inst == 'cymbal'
end

# Returns the correct config section for any instrument
define :cfg_inst_root do |cfg, inst|
  is_drum?(inst) ? cfg['drums'][inst] : cfg[inst]
end

# Returns the config key that holds the instrument/sample name
define :inst_name_key do |inst|
  case inst
  when 'solo' then 'inst'
  when 'kick', 'snare', 'cymbal' then 'sample'
  else 'synth'
  end
end

# Returns ADSR envelope parameters as a hash
define :adsr_opts do |adsr|
  { attack: adsr[0], attack_level: adsr[1], decay: adsr[2], decay_level: adsr[3],
    sustain: adsr[4], sustain_level: adsr[5], release: adsr[6], release_level: adsr[7] }
end

# Builds a JSON-like key:value string for OSC dropdown population
define :build_json_choices do |items, format_keys=true|
  items.map { |n|
    k = format_keys ? split_and_capitalize(n.to_s, "_") : n.to_s
    "\"#{k}\": \"#{n}\""
  }.join(", ")
end