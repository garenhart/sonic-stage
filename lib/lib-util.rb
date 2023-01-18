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

# Inserts 'el' after each element in 'arr'
define :insert_after_each_element do |arr, el|
    arr.map {|x| [x, el]}.flatten
end