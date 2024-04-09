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
    cfg[inst]['fx'][n] ||= ["", 0, 0]
    cfg[inst]['fx'][n][nn] = v
  else
    cfg[inst]['fx'] = [["", 0, 0]]
    cfg[inst]['fx'][n][nn] = v
  end  
end  