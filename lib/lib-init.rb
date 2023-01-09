#######################
# lib-init.rb
# initialization/configuration library
# author: Garen H.
#######################

# get the sample group name from a sample name (first substring before "_")
define :sample_group do |s|
  s.split("_").first
end

# Time State drum beats
define :init_time_state do |cfg|
  set :cymbal, cfg['cymbal']['beats']
  set :snare, cfg['snare']['beats']
  set :kick, cfg['kick']['beats']

  set :cymbal_inst, cfg['cymbal']['sample']
  set :snare_inst, cfg['snare']['sample']
  set :kick_inst, cfg['kick']['sample']
end

define :init_tonics do |cfg|
  cfg['tonics'] = []
  cfg['bass']['pattern'] = []
  cfg['chords']['pattern'] = []
end

define :init_keyboard do |tonic, mode|
  scale_notes = scale tonic, mode
  for note in 21..107
    osc_ctrl "/keyboard_scale", note, (scale_notes.to_a.include? note) ? 1 : 0
  end
end

define :init_drum do |d, gr_ctrl, inst_ctrl, cfg|
  sample_gr = sample_group(cfg[d]['sample'])
  osc_ctrl "/#{d}", cfg[d]['on'] ? 1 : 0
  osc_ctrl "/#{d}_amp", cfg[d]['amp']
  osc_ctrl gr_ctrl, sample_gr
  populate_samples inst_ctrl + "_v", sample_gr.to_sym
  sleep 0.125 # sleeping between populating and selecting seems to make it work 
  osc_ctrl inst_ctrl, (cfg[d]['sample'])
  16.times do |i|
    osc_ctrl "/#{d}_beats/#{i}", cfg[d]['beats'][i] #should figure out how to populate beats without looping through array
  end
  # osc_ctrl "/#{d}_beats", cfg[d]['beats']
  # set (d.to_sym), cfg[d]['beats'] #set the beats to for the drum
end

define :init_drums do |cfg|
  osc_ctrl "/drums", 1
  osc_ctrl "/dropdown_drum_tempo_factor", cfg['drum_tempo_factor']
  init_drum "kick", "/kick_inst_groups", "/kick_inst", cfg
  init_drum "snare", "/snare_inst_groups", "/snare_inst", cfg
  init_drum "cymbal", "/cymbal_inst_groups", "/cymbal_inst", cfg
end

define :init_controls do |cfg|
  osc_ctrl "/tempo", cfg['tempo']
  osc_ctrl "/pattern_mode", cfg['pattern_mode']
  osc_ctrl "/pattern", cfg['pattern']
  osc_ctrl "/switch_loop", cfg['loop_mode']
  osc_ctrl "/mode", cfg['mode']
  osc_ctrl "/scale", cfg['scale']
  osc_ctrl "/bass_inst", cfg['bass']['synth']
  osc_ctrl "/bass_amp", cfg['bass']['amp']
  osc_ctrl "/chord_type", cfg['chords']['type']
  osc_ctrl "/chord_inst", cfg['chords']['synth']
  osc_ctrl "/chord_amp", cfg['chords']['amp']
  
  osc_ctrl "/bass_points", cfg['tonics'].length
  osc_ctrl "/chord_points", cfg['tonics'].length
  init_keyboard(cfg['tonics'][0], cfg['scale'])

  init_drums cfg
end

  