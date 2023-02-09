#######################
# lib-osc.rb
# osc library
# author: Garen H.
#######################

# directs osc message to open stage control
define :osc_ctrl do |path, *args|
  osc_send get(:ctrl_ip), get(:ctrl_port), path, *args
end

# populates osc variable target with the list of SPi sample names
# for the specified sample group sg
define :init_osc_samples do |target, sg|
  puts "pop", target, sg
  return if target==nil or sg==nil
  sn = sample_names(sg)
  sn_str = "{"
  # convert to array of strings
  for n in sn
    sn_str += ", " if sn_str.length > 2
    sn_str += "\"" + n.to_s + "\": \"" + n.to_s + "\""
  end
  sn_str += "}"
  osc_ctrl target, sn_str
end

define :init_osc_keyboard do |tonic, mode|
  scale_notes = scale tonic, mode
  for note in 21..107
    osc_ctrl "/keyboard_scale", note, (scale_notes.to_a.include? note) ? 1 : 0
  end
end

define :init_osc_drum do |d, gr_ctrl, inst_ctrl, cfg|
  sample_gr = sample_group(cfg[d]['sample'])
  osc_ctrl "/#{d}", cfg[d]['on'] ? 1 : 0
  osc_ctrl "/#{d}_amp", cfg[d]['amp']
  osc_ctrl gr_ctrl, sample_gr
  init_osc_samples inst_ctrl + "_v", sample_gr.to_sym
  sleep 0.125 # sleeping between populating and selecting seems to make it work 
  osc_ctrl inst_ctrl, (cfg[d]['sample'])
  16.times do |i|
    osc_ctrl "/#{d}_beats/#{i}", cfg[d]['beats'][i] #should figure out how to populate beats without looping through array
  end
  # osc_ctrl "/#{d}_beats", cfg[d]['beats']
  # set (d.to_sym), cfg[d]['beats'] #set the beats to for the drum
end

define :init_osc_drums do |cfg|
  osc_ctrl "/drums", 1
  osc_ctrl "/dropdown_drum_tempo_factor", cfg['drum_tempo_factor']
  init_osc_drum "kick", "/kick_inst_groups", "/kick_inst", cfg
  init_osc_drum "snare", "/snare_inst_groups", "/snare_inst", cfg
  init_osc_drum "cymbal", "/cymbal_inst_groups", "/cymbal_inst", cfg
end

define :update_osc_bass_point_positions do |cfg|
  pos = insert_after_each_element(cfg['bass']['pattern'], 0)
  osc_ctrl("/bass_points_pos", *pos)
end

define :update_osc_chord_point_positions do |cfg|
  pos = insert_after_each_element(cfg['chords']['pattern'], 0)
  osc_ctrl("/chord_points_pos", *pos)
end

define :init_osc_tonics do |cfg|
  tonic_names = notes_to_names(cfg['tonics']).to_s
  puts "TONICS", tonic_names
  osc_ctrl("/bass_points", tonic_names)
  osc_ctrl("/chord_points", tonic_names)
  osc_ctrl("/scale_match", (notes_in_scale cfg['tonics'], cfg['scale'], cfg['tonics'][0]) ? 1 : 0)

  update_osc_bass_point_positions cfg
  update_osc_chord_point_positions cfg
end

define :init_osc_controls do |cfg|
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

  init_osc_tonics cfg
  init_osc_keyboard(cfg['tonics'][0], cfg['scale'])

  init_osc_drums cfg
end

# populates osc variable target with the list of SPi sample groups
# define :osc_populate_sample_groups do |target|
#   return if target==nil
#   sg = sample_groups
#   sg_str = []
#   # convert to array of strings
#   for n in sg
#     sg_str.push n.to_s
#   end
#   osc_ctrl target, sg_str.to_s
# end
