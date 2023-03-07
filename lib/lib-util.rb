#######################
# lib-util.rb
# utility library
# author: Garen H.
#######################

# 'pseudo'-evenly distributes 'count' positions within number of 'slots'
# returns distributed position for 'item_num' 
define :dist_pos do |item_num, count, slots| 
    pos = item_num * (slots / count)
end

# Inserts 'el' after each element in 'arr' and returns the new array
define :insert_after_each_element do |arr, el|
    arr.map {|x| [x, el]}.flatten
end

# Splits string 'str' into words based on pattern and capitalizes each word
define :split_and_capitalize do |str, pattern|
    str.split(pattern).map {|x| x.capitalize}.join(" ")
end

