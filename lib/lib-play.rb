#######################
# lib-play.rb
# Play library
# author: Garen H.
#######################

# define :pattern_match do |pattern, match=BEAT_on|
#   return pattern.ring.tick == match
# end

define :play_cue do |cfg|
  use_real_time
  use_bpm cfg['tempo']
  cue :tick
  cfg['bass']['count'].times do
    sleep 0.25
  end
end

define :play_drum do |drum, cfg|
  use_real_time
  use_bpm cfg['tempo']
  sync :tick
  # get drum data from Time State
  drums = get(:drums)
  tempo_factor = drums['tempo_factor']
  beats = drums[drum]['beats']
  amp = drums[drum]['amp']

  density tempo_factor do
    puts "drum=====: #{drums['count']} #{beats.size}"
    drums['count'].times do |i|
      if drums[drum]['on'] && (beats[i] == "1")
        sample drums[drum]['sample'], amp: amp
        animate_drum drum, amp
      end
      sleep 0.25
    end
  end
end

define :play_bass do |cfg|
  use_real_time
  use_bpm cfg['tempo']

  sync :tick

  cfg_bass = get(:bass_state)
  tempo_factor = cfg_bass['tempo_factor']
  puts "bass=====: #{cfg_bass['pattern'].size} #{cfg_bass['tonics'].size}"
  if ((cfg_bass['pattern'].size > 0) && (cfg_bass['pattern'].size == cfg_bass['tonics'].size))
    use_synth cfg_bass['synth'].to_sym
    puts "INST", cfg_bass['synth']

    density tempo_factor do
      cfg_bass['count'].times do |i|
        pos = cfg_bass['pattern'].index(i+1)
        if (cfg_bass['on'] && pos)
          play cfg_bass['tonics'][pos], amp: cfg_bass['amp']
          animate_POC(cfg_bass['tonics'][pos])
        end
        sleep 0.25
      end
    end
  else
    sleep 0.25
  end
end

define :play_chords do |cfg|
  use_real_time
  use_bpm cfg['tempo']
  
  sync :tick
  
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
          end        
        else
          chord_num = pos-last_pos
          if (cs != nil) && (chord_num < cs.length) && (pos < cfg_chord['count'])
            puts "III", pos
            play cs[chord_num], amp: cfg_chord['amp']
          end
        end
        sleep 0.25
      end
    end
  else
    sleep 0.25
  end
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
