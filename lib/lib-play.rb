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
  use_bpm cfg['tempo']
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
  use_bpm cfg['tempo']
  sync :tick
  # get drum data from Time State
  drums = get(:drums)
  tempo_factor = drums['tempo_factor']
  beats = drums[drum]['beats']
  count = drums['count']

  with_fx :reverb, room: 0.9, mix: 0.5 do
    density tempo_factor do
      count.times do |i|
        rt_drums = get(:drums) # drum data from Time State for params that we want to change in real time
        amp = rt_drums[drum]['amp']
        start = rt_drums[drum]['reverse'] ? rt_drums[drum]['range'][1] : rt_drums[drum]['range'][0]
        finish = rt_drums[drum]['reverse'] ? rt_drums[drum]['range'][0] : rt_drums[drum]['range'][1]
        pitch_shift = rt_drums[drum]['pitch_shift']

        if rt_drums[drum]['on'] 
          if (beats[i] == "1")
            if (rt_drums[drum]['random'])
              sample rt_drums[drum]['sample'], amp: amp, onset: pick, rpitch: pitch_shift, pitch_dis: 0.001, time_dis: 0.001
            else  
              if (start == finish)
                sample rt_drums[drum]['sample'], amp: amp, onset: 0, rpitch: pitch_shift, pitch_dis: 0.001, time_dis: 0.001
              else
                sample rt_drums[drum]['sample'], amp: amp, start: start, finish: finish, rpitch: pitch_shift, pitch_dis: 0.001, time_dis: 0.001
              end
            end  
            animate_drum drum, amp, 1, 1
          else
            animate_drum drum, amp, 0, 1
          end
        else
          animate_drum drum, amp, 0, 0   
        end
        sleep rhythm
      end
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

    with_fx :reverb, room: 0.9, mix: 0.5 do
      density tempo_factor do
        cfg_bass['count'].times do |i|
          pos = cfg_bass['pattern'].index(i+1)
          if (cfg_bass['on'] && pos)
            play cfg_bass['tonics'][pos], amp: cfg_bass['amp']
            animate_keyboard "bass", cfg_bass['tonics'][pos], cfg_bass['amp']
          # else
          #   animate_keyboard "bass", 0, 0.0
          end
          sleep rhythm
        end
      end
    end
  else
    sleep rhythm
  end
end

define :play_chords do |cfg|
  use_real_time
  use_bpm cfg['tempo']
  
  sync :tick
  
  cfg_chord = get(:chord_state)
  tempo_factor = cfg_chord['tempo_factor']

  if (cfg_chord['pattern'].size > 0) && (cfg_chord['pattern'].size == cfg_chord['tonics'].size)
    use_synth cfg_chord['synth'].to_sym
 
    with_fx :reverb, room: 0.9, mix: 0.5 do
        density tempo_factor do
        cfg_chord['count'].times do |pos|
          i = cfg_chord['pattern'].index(pos+1)
          if (cfg_chord['on'] && i)
            play (cfg_chord['tonics'][i]), amp: cfg_chord['amp']
            animate_keyboard "chord", cfg_chord['tonics'][i], cfg_chord['amp']
          # else
          #   animate_keyboard "chord", 0, 0.0    
          end
          sleep rhythm
        end
      end
    end
  else
    sleep rhythm
  end
end

define :play_chords_complex do |cfg|
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
    with_fx :reverb, room: 0.9, mix: 0.5 do
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

define :play_midi do |cfg, addr_data, note, vel|
  if (cfg['solo_on'] and addr_data[1] == "note_on" and vel > 0) # note_on 
    bass_rec = get(:bass_rec)
    chord_rec = get(:chord_rec) 
    next_beat = get(:beat) + 1
   
    if (bass_rec || chord_rec) # recording
      if (bass_rec)
          use_synth cfg['bass']['synth'].to_sym
          add_tonic_bass cfg, note, next_beat > cfg['bass']['count'] ? 1 : next_beat
          animate_keyboard "bass", note, vel/127.0
      end
      if (chord_rec)
          use_synth cfg['chord']['synth'].to_sym
          add_tonic_chord cfg, note, next_beat > get(:chord_state)['count'] ? 1 : next_beat
          animate_keyboard "chord", note, vel/127.0
      end
      with_fx :reverb, room: 0.9, mix: 0.5 do
        play note, amp: vel/127.0, release: 1
      end
    else # not recording
      with_effects fx_chain(cfg['solo_fx']) do
        use_synth cfg['solo_inst'].to_sym
        play note, amp: vel/127.0, release: 1
      end
      animate_keyboard "solo", note, vel/127.0
     end   
  end  
end

def fx_chain_rand(cfg_fx)
  if cfg_fx && cfg_fx.length > 0
    chain = lambda do
      [
        {with_fx: :echo, phase: rrand(0,0.5)},
        {with_fx: :whammy, grainsize: rrand(0,2.0)},
        {with_fx: :flanger, feedback: rrand(0,0.5)},
        {with_fx: :tremolo, phase: rrand(0,0.5)},
        {with_fx: :bitcrusher, bits: rand_i(3..5)}
      ].pick(3) # Use all or pick some randomly
    end
  else
    chain = lambda do
      [{with_fx: :none}]
    end
  end
  chain.call
end

def fx_chain(cfg_fx)
  if cfg_fx && cfg_fx.length > 0
    chain = lambda do
      cfg_fx.map do |fx|
        options = { with_fx: fx[0].to_sym }
        options[:mix] = fx[1].is_a?(Array) ? rrand(fx[1][0], fx[1][1]) : fx[1]
        options[:room] = fx[2].is_a?(Array) ? rrand(fx[2][0], fx[2][1]) : fx[2] if fx[0].to_sym == :reverb
        options[:phase] = fx[2].is_a?(Array) ? rrand(fx[2][0], fx[2][1]) : fx[2] if fx[0].to_sym == :echo
        options
      end
    end
  else
    chain = lambda do
      [{ with_fx: :none }]
    end
  end
  puts "FX CHAIN =============================", chain.call
  chain.call
end


# This method and the idea of using it is borrowed from 
# @amiika here: https://in-thread.sonic-pi.net/t/snake-jazz-also-is-there-an-fx-stack/5932/3
def with_effects(x, &block)
  x = x.dup
  if x.length>0 then
    n = x.shift
    if n[:with_fx] then
      with_fx n[:with_fx], n do
        with_effects(x, &block)
      end
    end
  else
    yield
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
