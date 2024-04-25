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

# Inserts 'el' after each element in 'arr' and returns the new array
define :insert_after_each_element do |arr, el|
    arr.map {|x| [x, el]}.flatten
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