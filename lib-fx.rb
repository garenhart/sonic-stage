#######################
# lib-fx.rb
# fx library
# author: Garen H.
#######################

# returns the name of the fx option based on the fx and option number
define :fx_option_name do |fx, option|
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
  
  