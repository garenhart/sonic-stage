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
define :animate_drum do |drum_inst, amp, beat_on, on|
  # osc "/drum", drum # drum component
  animate_drum_at get(:anim_ip), get(:anim_port), drum_inst, amp, beat_on, on
end

# sends OSC messages with note
define :animate_keyboard do |key_inst, note, amp|
  animate_keyboard_at get(:anim_ip), get(:anim_port), key_inst, note, amp
end

# As animate_drum / animate_keyboard, but with the Processing address supplied by
# the caller. osc_anim resolves :anim_ip and :anim_port with two `get`s, and every
# get costs a hard 1ms Kernel.sleep inside Sonic Pi's EventHistory#wait_for_threads
# (it is the thread-sync point for time state) -- 2ms of stall per animated beat.
# Loops that animate every beat hoist the pair once and call these; one-shot
# callers (the MIDI loops) keep the convenient forms above.
define :animate_drum_at do |ip, port, drum_inst, amp, beat_on, on|
  osc_send ip, port, "/drum", drum_inst, amp, beat_on, on
end

define :animate_keyboard_at do |ip, port, key_inst, note, amp|
  osc_send ip, port, "/key", key_inst, note, amp
end


# directs osc message to Processing
define :osc_anim do |path, *args|
  osc_send get(:anim_ip), get(:anim_port), path, *args
end
