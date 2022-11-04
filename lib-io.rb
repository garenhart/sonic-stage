# configuration folder path
configFilePath = get(:sp_path) + "live-impro\\sonic-pi-open-stage-control\\config\\" #path for config files

# read from JSON file and return parsed hash
define :gl_readJSON do |file_name|
    file = File.read(configFilePath + file_name +".json") 
    return JSON.parse(file)
    # return  MultiJson.load(file) # this works as well
end

# save hash into JSON file
define :gl_writeJSON do |file_name, hash|
    File.write(configFilePath + file_name +".json", JSON.dump(hash)) 
end
