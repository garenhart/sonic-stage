#######################
# lib-fx.rb
# fx library
# author: Garen H.
#######################

# returns the name of the most essential fx option based on the fx and option priority (1 or 2)
# e.g. fx_option_name("echo", 1) => "phase"
define :fx_option_name do |fx, n|
  case fx
  when "echo"
    n == 1 ? "phase" : "decay"
  when "whammy"
    n == 1 ? "grainsize" : "smooth"
  when "flanger"
    n == 1 ? "feedback" : "depth"
  when "tremolo"
    n == 1 ? "phase" : "depth"
  when "bitcrusher"
    n == 1 ? "bits" : "mix"
  when "reverb", "gverb"
    n == 1 ? "room" : "mix"
  when "distortion"
    n == 1 ? "distort" : "mix"
  when "wooble", "ixi_techno"
    n == 1 ? "phase" : "cutoff"
  when "slicer"                        
    n == 1 ? "phase" : "wave"
  when "rhpf", "rhpf", "rlpf", "hpf", "lpf"
    n == 1 ? "cutoff" : "res"
  when "compressor"
    n == 1 ? "amp" : "mix"
  when "pan"
    n == 1 ? "pan" : "amp"
  when "ring_mod"
    n == 1 ? "freq" : "amp"
  when "vowel"
    n == 1 ? "voice" : "mix"
  else
    # the most common options
    n == 1 ? "phase" : "decay"
  end
end
  
define :init_fx_component do |cfg, inst, n, nn, v|
  puts "init_fx_component: #{inst} #{n} #{nn} #{v}"
  if cfg[inst]['fx']
    cfg[inst]['fx'][n] ||= ["none", 0, 0]
    cfg[inst]['fx'][n][nn] = v
  else
    cfg[inst]['fx'] = [["none", 0, 0], ["none", 0, 0]]
    cfg[inst]['fx'][n][nn] = v
  end  
end

define :fx_chain_rand do |cfg_fx|
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

define :fx_chain do |cfg_fx|
  if cfg_fx && cfg_fx.length > 0
    chain = lambda do
      cfg_fx.map do |fx|
        puts "FX", fx
        options = { with_fx: fx[0].to_sym }
        options[fx_option_name(fx[0], 1).to_sym] = fx[1].is_a?(Array) ? rrand(fx[1][0], fx[1][1]) : fx[1]
        options[fx_option_name(fx[0], 2).to_sym] = fx[2].is_a?(Array) ? rrand(fx[2][0], fx[2][1]) : fx[2]
        options
      end
    end
  else
    chain = lambda do
      [{ with_fx: :none }]
    end
  end
  puts "FX CHAIN = ", chain.call
  chain.call
end

# This method and the idea of using it is borrowed from 
# @amiika here: https://in-thread.sonic-pi.net/t/snake-jazz-also-is-there-an-fx-stack/5932/3
# gh: only works with def, not define
def with_effects (x, &block)
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

