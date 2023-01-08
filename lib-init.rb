#######################
# lib-init.rb
# initialization/configuration library
# gl_ prefix is used for methods to indicate "garen's library"
#     in absence of support for namespaces and classes 
# author: Garen H.
#######################

# get the sample group name from a sample name (first substring before "_")
define :gl_sample_group do |s|
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

define :gl_init_keyboard do |tonic, mode|
  scale_notes = scale tonic, mode
  for note in 21..107
    gl_osc_ctrl "/keyboard_scale", note, (scale_notes.to_a.include? note) ? 1 : 0
  end
end

define :init_drum do |d, gr_ctrl, inst_ctrl, cfg|
  sample_gr = gl_sample_group(cfg[d]['sample'])
  gl_osc_ctrl "/#{d}", cfg[d]['on'] ? 1 : 0
  gl_osc_ctrl "/#{d}_amp", cfg[d]['amp']
  gl_osc_ctrl gr_ctrl, sample_gr
  gl_populate_samples inst_ctrl + "_v", sample_gr.to_sym
  sleep 0.125 # sleeping between populating and selecting seems to make it work 
  gl_osc_ctrl inst_ctrl, (cfg[d]['sample'])
  16.times do |i|
    gl_osc_ctrl "/#{d}_beats/#{i}", cfg[d]['beats'][i] #should figure out how to populate beats without looping through array
  end
  # gl_osc_ctrl "/#{d}_beats", cfg[d]['beats']
  # set (d.to_sym), cfg[d]['beats'] #set the beats to for the drum
end

define :init_drums do |cfg|
  gl_osc_ctrl "/drums", 1
  gl_osc_ctrl "/dropdown_drum_tempo_factor", cfg['drum_tempo_factor']
  init_drum "kick", "/kick_inst_groups", "/kick_inst", cfg
  init_drum "snare", "/snare_inst_groups", "/snare_inst", cfg
  init_drum "cymbal", "/cymbal_inst_groups", "/cymbal_inst", cfg
end

define :init_controls do |cfg|
  gl_osc_ctrl "/tempo", cfg['tempo']
  gl_osc_ctrl "/pattern_mode", cfg['pattern_mode']
  gl_osc_ctrl "/pattern", cfg['pattern']
  gl_osc_ctrl "/switch_loop", cfg['loop_mode']
  gl_osc_ctrl "/mode", cfg['mode']
  gl_osc_ctrl "/scale", cfg['scale']
  gl_osc_ctrl "/bass_inst", cfg['bass']['synth']
  gl_osc_ctrl "/bass_amp", cfg['bass']['amp']
  gl_osc_ctrl "/chord_type", cfg['chords']['type']
  gl_osc_ctrl "/chord_inst", cfg['chords']['synth']
  gl_osc_ctrl "/chord_amp", cfg['chords']['amp']
  
  gl_osc_ctrl "/bass_points", cfg['tonics'].length
  gl_osc_ctrl "/chord_points", cfg['tonics'].length
  gl_init_keyboard(cfg['tonics'][0], cfg['scale'])

  init_drums cfg
end

  