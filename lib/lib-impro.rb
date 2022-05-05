#######################
# lib-impro.rb
# Improvisation library
# gl_ prefix is used for methods to indicate "garen's library"
#     in absence of support for namespaces and classes 
# author: Garen H.
#######################

define :gl_play_drum do |drum_sample, beats, amp, on=true|
  16.times do |i|
    if beats[i] == 1 && on
      sample drum_sample, amp: amp
    end
    sleep 0.25
  end
end

define :gl_play_bass do |tonics, tonics_pos, amp|
  if (tonics_pos.size > 0) && (tonics_pos.size == tonics.size)
    16.times do |i|
      pos = tonics_pos.index(i)
      if (pos)
        play tonics[pos], amp: amp
      end
      sleep 0.25
    end
  else
    sleep 0.25
  end
end

define :gl_play_chords do |tonics, tonics_pos, amp, scale, pattern, chord_type|
  if (tonics_pos.size > 0) && (tonics_pos.size == tonics.size)
    seq = 1
    case pattern
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
    case chord_type
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
        cs = gl_chord_seq(tonics[i], scale, seq, seven, rootless)
        puts "chords", cs
        play (tonic ? cs[0][0] : cs[0]), amp: amp
      else
        chord_num = pos-last_pos
        if (chord_num < cs.length) && (pos < 16)
          puts "III", pos
          play cs[chord_num], amp: amp
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
define :dist_pos do |item_num, count, slots| 
  pos = item_num * (slots / count)
end