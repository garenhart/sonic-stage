#######################
# lib-play.rb
# Play library
# author: Garen H.
#######################

rhythm = 1.0 # each beat is a 1 whole note for 4/4 signature and lasts 1 sec for 60 BPM

# define :pattern_match do |pattern, match=BEAT_on|
#   return pattern.ring.tick == match
# end

define :play_cue do |cfg|
  use_real_time
  use_bpm get(:tempo)
  cue :tick
  drums = get(:drums)
  tempo_factor = drums['tempo_factor']
  # density tempo_factor do
    drums['count'].times do |i|
      set :beat, i+1
      osc_ctrl "/current_beat", i+1
      sleep rhythm
    end
  # end  
end

define :play_drum do |drum, cfg|
  use_real_time
  sync :tick
  use_bpm get(:tempo)
  drums = get(:drums)
  beats = drums[drum]['beats']
  count = drums['count']
  auto_on = cfg['drums']['auto']

  with_effects fx_chain(drums[drum]['fx']) do
    density drums['tempo_factor'] do
      count.times do |i|
        rt_drum = auto_on ? get(:drums)[drum] : drums[drum] # real-time vs cached params
        amp = rt_drum['amp']
        beat_on = rt_drum['on'] && beats[i] == "1"

        if beat_on
          opts = { amp: amp, rpitch: rt_drum['pitch_shift'], pitch_dis: 0.001, time_dis: 0.001 }
          if rt_drum['random']
            opts[:onset] = pick
          elsif rt_drum['range'][0] == rt_drum['range'][1]
            opts[:onset] = 0
          else
            opts[:start] = rt_drum['reverse'] ? rt_drum['range'][1] : rt_drum['range'][0]
            opts[:finish] = rt_drum['reverse'] ? rt_drum['range'][0] : rt_drum['range'][1]
          end
          sample rt_drum['sample'], **opts
        end

        animate_drum drum, amp, (beat_on ? 1 : 0), (rt_drum['on'] ? 1 : 0) if rt_drum['animate']
        sleep rhythm
      end
    end
  end
end

# Shared playback logic for bass and chord instruments
define :play_tonal_instrument do |state_key, label, cfg|
  use_real_time
  sync :tick
  use_bpm get(:tempo)

  auto_on = cfg[label]['auto']
  cfg_inst = get(state_key)

  if cfg_inst['pattern'].size > 0 && cfg_inst['pattern'].size == cfg_inst['tonics'].size
    use_synth cfg_inst['synth'].to_sym

    with_effects fx_chain(cfg_inst['fx']) do
      density cfg_inst['tempo_factor'] do
        cfg_inst['count'].times do |i|
          rt_inst = auto_on ? get(state_key) : cfg_inst # real-time vs cached params
          pos = cfg_inst['pattern'].index(i + 1)
          if rt_inst['on'] && pos
            play cfg_inst['tonics'][pos], amp: rt_inst['amp'], **adsr_opts(cfg_inst['adsr'])
            animate_keyboard label, cfg_inst['tonics'][pos], rt_inst['amp'] if rt_inst['animate']
          end
          sleep rhythm
        end
      end
    end
  else
    sleep rhythm
  end
end

define :play_bass do |cfg|
  play_tonal_instrument :bass_state, "bass", cfg
end

define :play_chords do |cfg|
  play_tonal_instrument :chord_state, "chord", cfg
end

define :play_chords_complex do |cfg|
  use_real_time
  sync :tick
  use_bpm get(:tempo)
  
  cfg_chord = get(:chord_state)
  tempo_factor = cfg_chord['tempo_factor']

  if (cfg_chord['pattern'].size > 0) && (cfg_chord['pattern'].size == cfg_chord['tonics'].size)
    use_synth (cfg_chord['synth']).to_sym
    on = cfg_chord['on']


    seq = 1
    case cfg['pattern']
    when 1
      seq = [1]
    when 2
      seq = [1] # update later
    when 3
      seq = [1] # update later
    when 4
      seq = [2,5,1]
    end

    seven = false
    rootless = false
    tonic = false
    case cfg_chord['type']
    when 1
      tonic = true
    when 3
      rootless = true
    when 4
      seven = true
    when 5
      seven = true
      rootless = true
    end

    cs = []
    last_pos = 0
    with_effects fx_chain(cfg_chord['fx']) do
      density tempo_factor do
        cfg_chord['count'].times do |pos|
          i = cfg_chord['pattern'].index(pos+1)
          if ( on && i)
            ind = note_ind(cfg_chord['tonics'][i], cfg_chord['tonics'][0], cfg['scale'])
            puts "Nearest", ind, cfg_chord['tonics'][i], cfg_chord['tonics'][0], cfg['scale']
            seq = ind == nil ? nil : [ind+1]
            chord_tonic = cfg_chord['tonics'][0]
            while cfg_chord['tonics'][i] < chord_tonic do # bring tonic down to corresponding octave if current tonic[i] is lower than tonic[0]
              chord_tonic -= 12
            end
            while cfg_chord['tonics'][i]-chord_tonic >= 12 do # bring tonic up to corresponding octave if current tonic[i] is more than octave above tonic[0]
              chord_tonic += 12
            end
            cs = chord_seq(chord_tonic, cfg['scale'], seq, seven, rootless)
            puts "chord", cs
            if cs != nil
              play (tonic ? cs[0][0] : cs[0]), amp: cfg_chord['amp'] 
              puts "II", (tonic ? cs[0][0] : cs[0])
              animate_keyboard (tonic ? cs[0][0] : cs[0])
            end        
          else
            chord_num = pos-last_pos
            if (cs != nil) && (chord_num < cs.length) && (pos < cfg_chord['count'])
              puts "III", pos
              play cs[chord_num], amp: cfg_chord['amp']
              puts cs[chord_num]
              animate_keyboard cs[chord_num]
            end
          end
          sleep rhythm
        end
      end
    end
  else
    sleep rhythm
  end
end

define :play_midi_solo do |cfg, note, vel|
  amp = vel/127.0 * 2
  with_effects fx_chain(cfg['solo']['fx']) do
    play_synth_note cfg['solo']['inst'].to_sym, note, amp, cfg['solo']['adsr']
  end
  animate_keyboard "solo", note, amp if cfg['solo']['animate']
end

define :play_midi_bass do |cfg, note, vel, next_beat|
  use_bpm get(:tempo)
  amp = vel/127.0 * 2 * cfg['bass']['amp']
  with_effects fx_chain(cfg['bass']['fx']) do
    play_synth_note cfg['bass']['synth'].to_sym, note, amp, cfg['bass']['adsr']
  end
  animate_keyboard "bass", note, amp if cfg['bass']['animate']
  add_tonic_bass cfg, note, next_beat > cfg['bass']['count'] ? 1 : next_beat
end

define :play_midi_chord do |cfg, note, vel, next_beat|
  use_bpm get(:tempo)
  amp = vel/127.0 * 2 * cfg['chord']['amp']
  with_effects fx_chain(cfg['chord']['fx']) do
    play_synth_note cfg['chord']['synth'].to_sym, note, amp, cfg['chord']['adsr']
  end
  animate_keyboard "chord", note, amp if cfg['chord']['animate']
  add_tonic_chord cfg, note, next_beat > cfg['chord']['count'] ? 1 : next_beat
end


define :play_synth do |cfg_inst, pos|
    play cfg_inst['tonics'][pos], amp: cfg_inst['amp'], **adsr_opts(cfg_inst['adsr'])
end

define :play_synth_note do |inst, note, amp, adsr|
  synth inst, note: note, amp: amp, **adsr_opts(adsr)
end

# returns index of nearest note in scale
define :nearest_ind do |note, tonic, mode_scale|
  return nil if mode_scale.empty?
  scale_notes = scale tonic, mode_scale
  puts "scale notes", scale_notes
  i = 0
  while note_to_octave(note, tonic) > scale_notes[i] do
    i = i+1
  end
  return i
end

# returns index of the note in scale, or nil if the note is not in scale
define :note_ind do |note, tonic, mode_scale|
  return nil if mode_scale.empty?
  scale_notes = scale tonic, mode_scale
  octave_note = note_to_octave(note, tonic)
  puts "scale notes", scale_notes
  i = 0
  while octave_note > scale_notes[i] do
    i = i+1
  end
  return octave_note == scale_notes[i] ? i : nil
end
