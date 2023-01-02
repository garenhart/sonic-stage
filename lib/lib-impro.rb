#######################
# lib-impro.rb
# Improvisation library
# gl_ prefix is used for methods to indicate "garen's library"
#     in absence of support for namespaces and classes 
# author: Garen H.
#######################

# define :pattern_match do |pattern, match=BEAT_on|
#   return pattern.ring.tick == match
# end

define :gl_play_drum do |drum, cfg|
  use_real_time
  tempo_factor = cfg['drum_tempo_factor']
  use_bpm cfg['tempo']
  sync :tick
  drum_sample = cfg[drum]['sample']
  beats = get(drum.to_sym) # get the beats from Time State
  amp = cfg[drum]['amp']
  on = cfg[drum]['on']

  density tempo_factor do
    beats.length.times do |i|
      if on && (beats[i] == "1")
        sample drum_sample, amp: amp
        gl_animate_drum drum, amp
      end
      sleep 0.25
    end
  end
end

define :gl_play_bass do |tonics, tonics_pos, cfg|
  if (tonics_pos.size > 0) && (tonics_pos.size == tonics.size)
    16.times do |i|
      pos = tonics_pos.index(i)
      if (pos)
        play tonics[pos], amp: cfg['bass']['amp']
        gl_animate_POC(tonics[pos])
      end
      sleep 0.25
    end
  else
    sleep 0.25
  end
end

define :gl_play_chords do |tonics, tonics_pos, cfg|
  if (tonics_pos.size > 0) && (tonics_pos.size == tonics.size)
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
    case cfg['chords']['type']
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
    16.times do |pos|
      i = tonics_pos.index(pos)
      if (i)
        last_ind = pos
        # ind = gl_nearest_ind(tonics[i], tonics[0], cfg['scale'])
        ind = gl_note_ind(tonics[i], tonics[0], cfg['scale'])
        puts "Nearest", ind, tonics[i], tonics[0], cfg['scale']
        seq = ind == nil ? nil : [ind+1]
        chord_tonic = tonics[0]
        while tonics[i] < chord_tonic do # bring tonic down to corresponding octave if current tonic[i] is lower than tonic[0]
          chord_tonic -= 12
        end
        while tonics[i]-chord_tonic >= 12 do # bring tonic up to corresponding octave if current tonic[i] is more than octave above tonic[0]
          chord_tonic += 12
        end
        cs = gl_chord_seq(chord_tonic, cfg['scale'], seq, seven, rootless)
        puts "chords", cs
        if cs != nil
          play (tonic ? cs[0][0] : cs[0]), amp: cfg['chords']['amp'] 
        end        
      else
        chord_num = pos-last_pos
        if (cs != nil) && (chord_num < cs.length) && (pos < 16)
          puts "III", pos
          play cs[chord_num], amp: cfg['chords']['amp']
        end
      end
      sleep 0.25
    end
  else
    sleep 0.25
  end
end

# 'pseudo'-evenly distributes 'count' positions within number of 'slots'
# returns distributed position for 'item_num' 
define :gl_dist_pos do |item_num, count, slots| 
  pos = item_num * (slots / count)
end

# returns index of nearest note in scale
define :gl_nearest_ind do |note, tonic, mode_scale|
  return nil if mode_scale.empty?
  scale_notes = scale tonic, mode_scale
  puts "scale notes", scale_notes
  i = 0
  while gl_note_to_octave(note, tonic) > scale_notes[i] do
    i = i+1
  end
  return i
end

# returns index of the note in scale, or nil if the note is not in scale
define :gl_note_ind do |note, tonic, mode_scale|
  return nil if mode_scale.empty?
  scale_notes = scale tonic, mode_scale
  octave_note = gl_note_to_octave(note, tonic)
  puts "scale notes", scale_notes
  i = 0
  while octave_note > scale_notes[i] do
    i = i+1
  end
  return octave_note == scale_notes[i] ? i : nil
end
