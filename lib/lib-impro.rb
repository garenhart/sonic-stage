#######################
# lib-impro.rb
# author: Garen H.
#######################

define :li_play_drum do |drum_sample, beats, amp, on=true|
  16.times do |i|
    if beats[i] == 1 && on
      sample drum_sample, amp: amp
    end
    sleep 0.25
  end
end

define :li_play_bass do |tonics, tonics_pos, amp|
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

define :li_play_chords do |tonics, tonics_pos, amp, mode, scale, pattern, chord_type|
  if (tonics_pos.size > 0) && (tonics_pos.size == tonics.size)
    m_scale = mode_scale mode, scale
    puts "SCALE", m_scale

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
    last_pos = -1
    last_ind = 0
    16.times do |i|
      pos = tonics_pos.index(i)
      if (pos)
        last_pos = pos
        last_ind = i
        cs = chord_seq(tonics[pos], m_scale, seq, seven, rootless)
        puts "chords", cs
        play (tonic ? cs[0][0] : cs[0]), amp: amp
      else
        chord_num = i-last_ind
        if (chord_num < cs.length) && (i < 16)
          puts "III", i
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