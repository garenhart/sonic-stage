#######################
# lib-defaults.rb
# defaults library
# author: Garen H.
#######################

define :ensure_defaults do |data|
    data = def_adsr(data)
    data = def_fx(data)
    return data
end

define :def_adsr do |data|
    # ensure all necessary keys are present
    if data["solo"]["adsr"] == nil
        data["solo"]["adsr"] = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]
    end
    if data["bass"]["adsr"] == nil
        data["bass"]["adsr"] = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]
    end
    if data["chord"]["adsr"] == nil
        data["chord"]["adsr"] = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]        
    end
    if data["drums"]["cymbal"]["adsr"] == nil
        data["drums"]["cymbal"]["adsr"] = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]
    end
    if data["drums"]["snare"]["adsr"] == nil
        data["drums"]["snare"]["adsr"] = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]
    end
    if data["drums"]["kick"]["adsr"] == nil
        data["drums"]["kick"]["adsr"] = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]
    end
    return data
end

define :def_fx do |data|
    if data["solo"]["fx"] == nil
        data["solo"]["fx"] = [["none", 0.9, 0.5], ["none", 0.9, 0.5]]
    end
    if data["bass"]["fx"] == nil
        data["bass"]["fx"] = [["none", 0.9, 0.5], ["none", 0.9, 0.5]]    
    end
    if data["chord"]["fx"] == nil
        data["chord"]["fx"] = [["none", 0.9, 0.5], ["none", 0.9, 0.5]]    
    end
    if data["drums"]["cymbal"]["fx"] == nil
        data["drums"]["cymbal"]["fx"] = [["none", 0.9, 0.5], ["none", 0.9, 0.5]]    
    end
    if data["drums"]["snare"]["fx"] == nil
        data["drums"]["snare"]["fx"] = [["none", 0.9, 0.5], ["none", 0.9, 0.5]]    
    end
    if data["drums"]["kick"]["fx"] == nil
        data["drums"]["kick"]["fx"] = [["none", 0.9, 0.5], ["none", 0.9, 0.5]]    
    end
    return data
end


