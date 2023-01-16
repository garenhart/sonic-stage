#######################
# lib-osc-animation.rb
# osc animation library
# via Processing interface
# author: Garen H.
#######################

# POC method to connect to Processing
define :animate_POC do |nv|
  sn = (note(nv)-36)*16 #scaled note to send
  
  osc_anim "/n", sn # scaled note info to set vertical pos
  osc_anim "/clr", sn, 128, 0 # color
  osc_anim "/rad", 50.0 # radius
end

# sends OSC messages with drum component and corresponding amp
define :animate_drum do |drum, amp|
  # osc "/drum", drum # drum component
  osc_anim "/#{drum}_amp", amp # drum component amp
end

# directs osc message to Processing
define :osc_anim do |path, *args|
  osc_send get(:anim_ip), get(:anim_port), path, *args
end
