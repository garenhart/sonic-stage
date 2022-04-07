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

define :li_play_chords do |tonics, tonics_pos, amp, mode, scale, chord_type|
  if (tonics_pos.size > 0) && (tonics_pos.size == tonics.size)
    m_scale = mode_scale mode, scale
    puts "SCALE", m_scale

    cs = []
    chord_num = 0
    16.times do |i|
      pos = tonics_pos.index(i)
      if (pos)
        chord_num = 2
        cs = chord_seq(tonics[pos], m_scale, [2,5,1])
        puts "chords", cs
        play cs[chord_num], amp: amp
#      else
#        chord_num = chord_num + 1
#        play cs[chord_num], amp: amp # if chord_num < cs.length && chord_num > 0
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