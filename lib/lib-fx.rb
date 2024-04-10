#######################
# lib-fx.rb
# fx library
# author: Garen H.
#######################

# returns the name of the fx option based on the fx and option number
define :fx_option_name do |fx, option|
  puts "fx_option_name: #{fx} #{option}"
    option_name = ""
    case option
    when 1
      option_name = "mix"
    when 2
      option_name = "room"
    end
  
    case fx
    when "echo"
      case option
      when 2
        option_name = "phase"
      end
    end
    return option_name
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

