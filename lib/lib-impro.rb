define :li_play_drum do |drum_sample, beats, amp, on=true|
  16.times do |i|
    if beats[i] == 1 && on
      sample drum_sample, amp: amp
    end
    sleep 0.25
  end
end

define :li_play_bass do |mode, tonics, tonics_pos, amp|
  puts "tonics", tonics
  puts "tonics pos", tonics_pos
  16.times do |i|
    if (tonics_pos.size > 0) && (tonics_pos.size == tonics.size) && (mode == 0)
      play tonics.tick, amp: amp
    end
    sleep 0.25
  end
end


define :li_root_sequence do |root, dur|
  16.times do
    play root
    sleep dur
  end
end
