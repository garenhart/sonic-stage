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
  # Open Stage Control address, hoisted out of the beat loop. osc_ctrl resolves
  # :ctrl_ip and :ctrl_port with two `get`s, and every get costs a hard 1ms
  # Kernel.sleep inside Sonic Pi's EventHistory#wait_for_threads -- 2ms of stall
  # before each /current_beat, which the UI playhead sees as lag. Both are set
  # once at startup and never change, so reading them per beat bought nothing.
  ctrl_ip = get(:ctrl_ip)
  ctrl_port = get(:ctrl_port)
  # density is deliberately NOT applied here, unlike play_drum. Sonic Pi's
  # `density d` runs its block d times with each sleep scaled to 1/d, so at
  # drum_tempo_factor > 1 the drums replay their pattern d times while this
  # counter sweeps it once, and the highlight lags the hits it should track.
  #
  # Enabling it is not a clean fix:
  #   - it multiplies /current_beat traffic by d, and the Open Stage Control
  #     client (the Android tablet) is the bottleneck here, not Sonic Pi
  #   - `set :beat` below is the MIDI recording position, so the drum factor
  #     would end up setting the recording resolution for bass and chord too
  #   - bass and chord carry their own tempo_factor dropdowns; one shared
  #     counter cannot track three independently scaled grids
  # Latent today: every config in config/ uses tempo_factor 1.
  # density tempo_factor do
    drums['count'].times do |i|
      set :beat, i+1
      osc_send ctrl_ip, ctrl_port, "/current_beat", i+1
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
  beat_mask = beats.chars.map { |c| c == "1" } # precompute once; beats string is not re-read per beat
  # Processing address, hoisted for the same reason as in play_cue: animate_drum
  # would otherwise pay 2ms of get-sleeps on every animated beat.
  anim_ip = get(:anim_ip)
  anim_port = get(:anim_port)

  with_effects fx_chain(drums[drum]['fx']) do
    density drums['tempo_factor'] do
      count.times do |i|
        rt_drum = auto_on ? get(:drums)[drum] : drums[drum] # real-time vs cached params
        amp = rt_drum['amp']
        beat_on = rt_drum['on'] && beat_mask[i]

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

        animate_drum_at anim_ip, anim_port, drum, amp, (beat_on ? 1 : 0), (rt_drum['on'] ? 1 : 0) if rt_drum['animate']
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

    # Structural data (pattern/tonics/adsr/synth) is fixed for the loop's duration,
    # so precompute once here. Only the live fields (on, amp) are read per beat below.
    tonics = cfg_inst['tonics']
    adsr = adsr_opts(cfg_inst['adsr'])
    # beat (1-based) -> index into tonics; reproduces pattern.index(i+1) as an O(1) lookup
    pos_by_beat = []
    cfg_inst['pattern'].each_with_index { |beat, idx| pos_by_beat[beat - 1] = idx }
    # Processing address, hoisted for the same reason as in play_cue: animate_keyboard
    # would otherwise pay 2ms of get-sleeps on every animated beat.
    anim_ip = get(:anim_ip)
    anim_port = get(:anim_port)

    with_effects fx_chain(cfg_inst['fx']) do
      density cfg_inst['tempo_factor'] do
        cfg_inst['count'].times do |i|
          rt_inst = auto_on ? get(state_key) : cfg_inst # real-time vs cached params (live fields only: on, amp)
          pos = pos_by_beat[i]
          if rt_inst['on'] && pos
            play tonics[pos], amp: rt_inst['amp'], **adsr
            animate_keyboard_at anim_ip, anim_port, label, tonics[pos], rt_inst['amp'] if rt_inst['animate']
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

define :play_midi_solo do |cfg, note, vel|
  use_bpm get(:tempo) # required so adsr/fx times (in beats) scale like bass/chord; else solo runs at default 60 BPM and sounds different
  amp = vel/127.0 * 2 * (cfg['solo']['amp'] || 0.5) # 2x headroom: fader 0.5 = old max, 1.0 = double (may distort); || 0.5 keeps configs without a solo amp at their original loudness
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
