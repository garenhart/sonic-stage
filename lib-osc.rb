#######################
# lib-osc.rb
# osc library
# author: Garen H.
#######################

# directs osc message to open stage control
define :osc_ctrl do |path, *args|
  osc_send get(:ctrl_ip), get(:ctrl_port), path, *args
end

# populates osc variable with the list of SPi synth names
define :init_osc_synths do
  sn = synth_names
  sn_str = "{"
  # convert to array of strings
  for n in sn
    sn_str += ", " if sn_str.length > 2
    sn_str += "\"" + split_and_capitalize(n.to_s, "_") + "\": \"" + n.to_s + "\""
  end
  sn_str += "}"
  osc_ctrl "/synths", sn_str 
end

# populates osc variable with the list of SPi sample group names
define :init_osc_sample_groups do
  sg = sample_groups
  sg_str = "{"
  # convert to array of strings
  for n in sg
    sg_str += ", " if sg_str.length > 2
    sg_str += "\"" + split_and_capitalize(n.to_s, "_") + "\": \"" + n.to_s + "\""
  end
  # add a "Favorites" group to the end of the list
  sg_str += ", \"Favorites\": \"favorites\""
  sg_str += "}"
  osc_ctrl "/sample_groups", sg_str 
end

define :sample_favorites do |target, cfg|
  # get the drum portion of the target string (e.g. "/kick_inst_v" -> "kick")
  d = target.split("_")[0].split("/")[1]
  # return the ring of favorite samples from cfg[drums][d][fav]
  return cfg['drums'][d]['fav'].map {|s| s.to_sym}
end

# populates osc variable target with the list of SPi sample names
# for the specified sample group sg
define :init_osc_samples do |target, sg, cfg|
  puts "pop", target, sg
  return if target==nil or sg==nil
  sn = sg == :favorites ? sample_favorites(target, cfg) : sample_names(sg)
  sn_str = "{"
  # convert to array of strings
  for n in sn
    sn_str += ", " if sn_str.length > 2
    sn_str += "\"" + n.to_s + "\": \"" + n.to_s + "\""
  end
  sn_str += "}"
  puts "Samples: ", sn_str
  osc_ctrl target, sn_str
end

define :init_osc_keyboard do |tonic, mode|
  start = Time.now
  scale_notes = scale tonic, mode
  sn = extract_between_brackets scale_notes.to_s
  puts sn
  osc_ctrl "/scale_notes", sn
  # for note in 21..107
  #   osc_ctrl "/keyboard_scale", note, (scale_notes.to_a.include? note) ? 1 : 0
  # end
  finish = Time.now
  puts "init_osc_keyboard time: #{scale_notes.to_s}, #{mode}, #{time_diff_ms start, finish}"
end

define :init_osc_update_drums do
  osc_ctrl "/drums_update", 0
  osc_ctrl "/drums_auto", get(:drums_auto) ? 1 : 0
end

define :init_osc_update_bass do
  osc_ctrl "/bass_update", 0
  osc_ctrl "/bass_auto", get(:bass_auto) ? 1 : 0
  osc_ctrl "/bass_rec", get(:bass_rec) ? 1 : 0
  osc_ctrl "/bass_del", 0
end

define :init_osc_update_chord do
  osc_ctrl "/chord_update", 0
  osc_ctrl "/chord_auto", get(:chord_auto) ? 1 : 0
  osc_ctrl "/chord_rec", get(:chord_rec) ? 1 : 0
  osc_ctrl "/chord_del", 0
end

define :init_osc_updates do
  init_osc_update_drums 
  init_osc_update_bass
  init_osc_update_chord
end

define :init_osc_drum do |d, gr_ctrl, inst_ctrl, cfg|
  sample_gr = sample_group(cfg['drums'][d]['sample'])
  osc_ctrl "/#{d}_on", cfg['drums'][d]['on'] ? 1 : 0
  osc_ctrl "/#{d}_amp", cfg['drums'][d]['amp']
  osc_ctrl "/#{d}_range", *cfg['drums'][d]['range']
  osc_ctrl "/#{d}_random", cfg['drums'][d]['random'] ? 1 : 0
  osc_ctrl "/#{d}_reverse", cfg['drums'][d]['reverse'] ? 1 : 0
  osc_ctrl "/#{d}_pitch_shift", cfg['drums'][d]['pitch_shift']

  osc_ctrl gr_ctrl, sample_gr
  init_osc_samples inst_ctrl + "_v", sample_gr.to_sym, cfg
  osc_ctrl inst_ctrl, (cfg['drums'][d]['sample'])
  osc_ctrl "/#{d}_fav", drum_fav?(cfg, d, cfg['drums'][d]['sample']) ? 1 : 0 # set fav button
 
  # populate drum beats osc widget with the beats from string
  # beat_count = cfg['drums'][d]['beats'].length  
  # beat_count.times do |i|
  #   osc_ctrl "/#{d}_beats/#{i}", cfg['drums'][d]['beats'][i] #should figure out how to populate beats without looping through array
  # end

  # populate drum beats osc widget with the beats from string
  # sending one osc message with entire string and parsing in open stage control
  # is a better idea than sending individual messages for each beat (above)
  # because sending individual messages is slow and causes a time lag
  osc_ctrl "/#{d}_beats_v", cfg['drums'][d]['beats']
  #set (d.to_sym), cfg['drums'][d]['beats'] #set the beats to for the drum
end

define :init_osc_drums do |cfg|
  osc_ctrl "/beat_pt_count", cfg['drums']['count']
  osc_ctrl "/drum_tempo_factor", cfg['drums']['tempo_factor']
  init_osc_drum "kick", "/kick_inst_groups", "/kick_inst", cfg
  init_osc_drum "snare", "/snare_inst_groups", "/snare_inst", cfg
  init_osc_drum "cymbal", "/cymbal_inst_groups", "/cymbal_inst", cfg
end

define :update_osc_bass_points do |cfg|
  osc_ctrl "/bass_pt_count", cfg['bass']['count']
  osc_ctrl "/bass_tempo_factor", cfg['bass']['tempo_factor']
  tonic_names = notes_to_names(cfg['bass']['tonics'])
  pos = insert_after_each_element(cfg['bass']['pattern'], 0)
  pts = [tonic_names, pos]
  puts "BASS PTS:", pts
  osc_ctrl("/bass_points", *[*tonic_names, *pos])
end

define :update_osc_chord_points do |cfg|
  osc_ctrl "/chord_pt_count", cfg['chord']['count']  
  osc_ctrl "/chord_tempo_factor", cfg['chord']['tempo_factor']
  tonic_names = notes_to_names(cfg['chord']['tonics'])
  pos = insert_after_each_element(cfg['chord']['pattern'], 0)
  pts = [tonic_names, pos]
  puts "CHORD PTS:", pts
  osc_ctrl("/chord_points", *[*tonic_names, *pos])
  update_scale_match cfg
end

define :update_scale_match do |cfg|
  osc_ctrl("/scale_match", (notes_in_scale cfg['chord']['tonics'], cfg['scale'], cfg['chord']['tonics'][0]) ? 1 : 0)
  init_osc_keyboard(cfg['chord']['tonics'][0], cfg['scale'])
end

define :init_osc_controls do |cfg, init_presets=false|
  if init_presets
    init_osc_updates
    init_osc_synths
    init_osc_sample_groups
  end

  osc_ctrl "/tempo", cfg['tempo']
  osc_ctrl "/pattern_mode", cfg['pattern_mode']
  osc_ctrl "/pattern", cfg['pattern']
  osc_ctrl "/mode", cfg['mode']
  osc_ctrl "/scale", cfg['scale']
  osc_ctrl "/switch_loop", cfg['loop_mode']
  osc_ctrl "/solo_inst", cfg['solo_inst']
  osc_ctrl "/solo_on", cfg['solo_on'] ? 1 : 0

  osc_ctrl "/bass_on", cfg['bass']['on'] ? 1 : 0
  osc_ctrl "/bass_amp", cfg['bass']['amp']
  osc_ctrl "/bass_inst", cfg['bass']['synth']
  osc_ctrl "/chord_on", cfg['chord']['on'] ? 1 : 0
  osc_ctrl "/chord_amp", cfg['chord']['amp']
  osc_ctrl "/chord_type", cfg['chord']['type']
  osc_ctrl "/chord_inst", cfg['chord']['synth']

  update_osc_bass_points cfg
  update_osc_chord_points cfg
  init_osc_drums cfg
end
