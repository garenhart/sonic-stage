######################################
# osc_monitor.pi
# monitor/player part (Sonic Pi)
# no name yet for this project (Sonic Pi - Open Stage Control - Processing)
# author: Garen H.
######################################

use_debug false
use_midi_logging false
use_cue_logging false
use_osc_logging false
use_arg_checks false

# use_transpose 0 #add optional transpose manually

#load libraries
require 'date'

# Use the ss_path variable from init.rb as the base path
project_root = get(:ss_path)

set :lib_path, project_root + 'lib/'
lib_path = get(:lib_path)

# configuration folder path
config_path = project_root + 'config/'

eval_file lib_path + 'lib-util.rb'
eval_file lib_path + 'lib-io.rb'
eval_file lib_path + 'lib-fav.rb'
eval_file lib_path + 'lib-fx.rb'
eval_file lib_path + 'lib-state.rb'
eval_file lib_path + 'lib-osc-animation.rb'
eval_file lib_path + 'lib-play.rb'
eval_file lib_path + 'lib-osc.rb'
eval_file lib_path + 'lib-dyn-live_loop.rb'
eval_file lib_path + 'lib-chord-gen.rb'
eval_file lib_path + 'lib-mon.rb'

#require get(:sp_path)+"sonic-stage-lib/modes.rb" # Load extra scales and chord from separate file
#ModeScales = Modes.scales

# generic midi definitions
midi_in = "/midi*/" # This one seems to work for most midi devices

# midi_in = "/midi:nanokey*/" # Korg nanoKey
# midi_in = "/midi*midi*/" # Komplete Kontrol M32
# midi_daw = "/midi*m_daw*/" # Komplete Kontrol M32 
#######

# Open Stage Control config
set :ctrl_ip, "127.0.0.1"
set :ctrl_port, 7777 # make sure to match Open Stage Control's osc-port value
# Processing config
set :anim_ip, "127.0.0.1"
set :anim_port, 8000 # make sure to match Processing osc-port value



bass_rec = false
chord_rec = false
set :bass_rec, bass_rec
set :chord_rec, chord_rec

puts "CTRL", :ctrl_ip, :ctrl_port

cfg_def = "_default.json"
cfgFile = config_path + cfg_def
# deserialize JSON file into cfg hash
cfg = initJSON(cfgFile)
osc_ctrl "/cfg_path", config_path # set the osc control path
osc_ctrl "/open", cfg_def # set the osc control file name

puts "cfg", cfg

# use_random_seed 31
# prog = [{tonic: :D, type: 'm7-5', invert: -1}, {tonic: :G, type: '7', invert: -1},{tonic: :C, type: 'mM7', invert: 1}]

# init osc controls twice to avoid blank instruments
init_time_state cfg
init_osc_controls cfg, true
# ---
sleep 1 # wait for init to finish

# set_audio_latency! -100 # set audio latency to -100ms

live_loop :drum_kick do
  play_drum "kick", cfg
end

live_loop :drum_snare do
  play_drum "snare", cfg
end

live_loop :drum_cymbal do
  play_drum "cymbal", cfg
end
# END DRUM LOOPS

live_loop :chord do
  play_chords cfg
end

live_loop :bass do
  play_bass cfg
end

live_loop :midi_solo do
  # WARNING: use_real_time must be set to true for this to work
  # WARNING: moving following 4 lines to play_midi() causing
  # first note to be skipped when new file is opened (why?)
  use_real_time

  addr = midi_in + "note_on"
  note, vel = sync addr
  
  # Play solo if velocity > 0, solo mode is on, and not recording bass or chord (to avoid conflicts)
  play_midi_solo cfg, note, vel if vel != 0 && cfg['solo']['on'] && !bass_rec && !chord_rec
end

live_loop :midi_bass do
  # WARNING: use_real_time must be set to true for this to work
  # WARNING: moving following 4 lines to play_midi() causing
  # first note to be skipped when new file is opened (why?)
  use_real_time

  addr = midi_in + "note_on"
  note, vel = sync addr
  
  # Play bass if recording and velocity > 0
  play_midi_bass cfg, note, vel, get(:beat) + 1 if bass_rec && vel != 0
end

live_loop :midi_chord do
  # WARNING: use_real_time must be set to true for this to work
  # WARNING: moving following 4 lines to play_midi() causing
  # first note to be skipped when new file is opened (why?)
  use_real_time

  addr = midi_in + "note_on"
  note, vel = sync addr
  
  # Play chord if recording and velocity > 0
  play_midi_chord cfg, note, vel, get(:beat) + 1 if chord_rec && vel != 0
end


# CUE LOOP (MUST BE LAST OF SYNC LOOPS!!!)
live_loop :the_cue do
  play_cue cfg
end

# OSC MESSAGE MONITORING LOOP
live_loop :osc_monitor do
  addr = "/osc:#{get(:ctrl_ip)}:#{get(:ctrl_port)}/**"
  n = sync addr
  token = parse_addr addr

  if token[1] == "open"
    cfgFile = n[0]
    cfg = initJSON(cfgFile)
    bass_rec = false
    chord_rec = false
    set :bass_rec, bass_rec
    set :chord_rec, chord_rec
    # update time state FIRST for immediate tempo/state sync across threads
    init_time_state cfg
    # init osc controls twice to avoid blank instruments
    init_osc_controls cfg
    init_osc_controls cfg
  else
    t = token[1].split("_")[0]
    handle_osc token, t, n, cfg, cfgFile
    bass_rec = get(:bass_rec)
    chord_rec = get(:chord_rec)
  end
end
# END OSC MESSAGE MONITORING LOOP
