#######################
# lib-osc-animation.rb
# osc animation library
# via Processing interface
# gl_ prefix is used for methods to indicate "garen's library"
#     in absence of support for namespaces and classes 
# author: Garen H.
#######################

# POC method to connect to Processing
define :gl_animate_POC do |nv|
  sn = (note(nv)-36)*16 #scaled note to send
  
  osc "/n", sn # scaled note info to set vertical pos
  osc "/clr", sn, 128, 0 # color
  osc "/rad", 50.0 # radius
end

# sends OSC messages with drum component and corresponding amp
define :gl_animate_drum do |drum, amp|
  # osc "/drum", drum # drum component
  osc "/#{drum}_amp", amp # drum component amp
end
