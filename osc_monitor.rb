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

require get(:sp_path)+"lib/modes.rb" # Load extra scales and chords from separate file
use_random_seed 31
ModeScales = Modes.scales
prog = [{tonic: :D, type: 'm7-5', invert: -1}, {tonic: :G, type: '7', invert: -1},{tonic: :C, type: 'mM7', invert: 1}]



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
set :style, 1
set :mode, 1
set :key_1, 0

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
  osc "/tempo", get(:tempo)
  osc "/style", get(:style)
  osc "/mode", get(:mode)
  osc "/key", get(:key_1), 1
  init_drums
end


init_controls

define :play_drum do |drum_sample, beats, on=true|
  16.times do |i|
    if beats[i] == 1 && on
      sample drum_sample
    end
    sleep 0.25
  end
end
# END DRUM CONFIG

# DRUM LOOPS
with_fx :reverb, room: 0.8, mix: 0.5 do |r|
  live_loop :drum_kick do
    use_real_time
    use_bpm get(:tempo)
    sync :tick
    play_drum :bd_tek, get(:kick), get(:kick_on)
  end
  
  live_loop :drum_snare do
    use_real_time
    use_bpm get(:tempo)
    sync :tick
    play_drum :drum_snare_soft, get(:snare), get(:snare_on)
  end
  
  live_loop :drum_hihat do
    use_real_time
    use_bpm get(:tempo)
    sync :tick
    play_drum :drum_cymbal_closed, get(:hihat), get(:hihat_on)
  end
end
# END DRUM LOOPS

# BASS LOOP
with_fx :reverb, damp: 0.9, room: 0.8 do
  live_loop :bass do
    use_real_time
    use_bpm get(:tempo)
    use_synth_defaults depth: -1, divisor: 1, release: [0.25,0.5].choose, amp: 1
    cue :tick
    
    puts "SSS", get(:style)
    case get(:style)
    when 1
      tonic = get(:key_1)
      if (tonic <= 0)
        sleep 0.125 #sleep until a valid tonic signal received
      else
        lowest_tonic = 28
        while tonic < lowest_tonic
          tonic+=12
        end
        4.times do |i|
          if tonic < lowest_tonic
            tonic += (4-i)*7
          end
          play tonic
          tonic -= 7
          sleep 1
        end
      end
    when 2
      sleep 0.5
    when 3
      sleep 0.5
    else
      sleep 0.5
    end
  end
end
#END BASS LOOP

# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
  addr = "/osc:#{get(:ip)}:#{get(:port)}/**"
  n = sync addr
  token   = parse_addr addr
  
  case token[1]
  when "tempo"
    set :tempo, n[0].to_i
    puts "tempo", get(:tempo)
    
  when "style"
    set :style, n[0].to_i
    puts "style", get(:style)
    
  when "key"
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

