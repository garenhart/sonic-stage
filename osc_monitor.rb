######################################
# osc_monitor.rb
# drum pad monitor/player
# Sonic Pi - Open Stage Control (poc)
# author: Garen H.
######################################

use_debug false

set :ip, "127.0.0.1"
set :port, 7777 # make sure to match Open Stage Control's osc-port value
use_osc get(:ip), get(:port)

define :parse_addr do |path|
  e = get_event(path).to_s
  v = e.split(",")[6]
  if v != nil
    return v[3..-2].split("/")
  else
    return ["error"]
  end
end

# CONFIG
set :tempo, 60
set :key_1, 48

# DRUM CONFIG
set :kick_on, false
set :snare_on, false
set :hihat_on, false
set :kick, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :snare, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
set :hihat, [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
kick = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
snare = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
hihat = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

define :init_drum do |d|
  osc "/#{d}", 0
  16.times do |i|
    osc "/#{d}_beats/#{i}", 0
  end
end

define :init_drums do
  osc "/drums", 0
  init_drum "kick"
  init_drum "snare"
  init_drum "hihat"
end

define :init_controls do
  osc "/input_tempo", get(:tempo)
  osc "/dropdown_styles", 1
  osc "/dropdown_modes", 1
  osc "/keyboard_1", get(:key_1), 1
  init_drums
end


init_controls

define :play_drum do |drum_sample, beats, on=true|
  16.times do |i|
    if beats[i] == 1 && on
      sample drum_sample
    end
    sleep 0.0625
  end
end
# END DRUM CONFIG

# DRUM LOOPS
with_fx :reverb, room: 0.8, mix: 0.5 do |r|
  live_loop :drum_kick do
    use_real_time
    use_bpm get(:tempo)
    play_drum :bd_tek, get(:kick), get(:kick_on)
  end
  
  live_loop :drum_snare do
    use_real_time
    use_bpm get(:tempo)
    play_drum :drum_snare_soft, get(:snare), get(:snare_on)
  end
  
  live_loop :drum_hihat do
    use_real_time
    use_bpm get(:tempo)
    play_drum :drum_cymbal_closed, get(:hihat), get(:hihat_on)
  end
end
# END DRUM LOOPS


# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
  addr = "/osc:#{get(:ip)}:#{get(:port)}/**"
  n = sync addr
  token   = parse_addr addr
  
  case token[1]
  
  when "input_tempo"
    set :tempo, n[0].to_i
    puts "tempo", get(:tempo)
    
  when "keyboard_1"
    if n[1] == 1
      set :key_1, n[0].to_i
    end
    puts "key", get(:key_1)
    
  when "drums" # update Time State
    set :kick, kick
    set :snare, snare
    set :hihat, hihat
    
    # set drum "on" status based on the button state
  when "kick"
    set :kick_on, n[0]==1.0
  when "snare"
    set :snare_on, n[0]==1.0
  when "hihat"
    set :hihat_on, n[0]==1.0
    
    # save beat states
  when "kick_beats"
    kick[token[2].to_i] = n[0].to_i
  when "snare_beats"
    snare[token[2].to_i] = n[0].to_i
  when "hihat_beats"
    hihat[token[2].to_i] = n[0].to_i
  end
end
# END OSC MESSAGE MONITORING LOOP

