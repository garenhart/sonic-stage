# configuration folder path
# configPath = get(:sp_path) + "live-impro\\sonic-pi-open-stage-control\\config\\" #path for config files

# read from JSON file and return parsed hash
define :gl_readJSON do |file_name|
    file = File.read(file_name) 
    return JSON.parse(file)
    # return  MultiJson.load(file) # this works as well
end

# insert suffix into file name before extension
define :gl_suffix_filename do |file_name, suffix|
    extension = File.extname(file_name)
    file_name.reverse.sub(extension.reverse, ("#{suffix}#{extension}").reverse).reverse
end

# save hash into JSON file
define :gl_writeJSON do |file_name, hash|
    File.write(file_name, JSON.dump(hash)) 
end

# create unique name based on current date-time and save hash into it
define :gl_write_unique_JSON do |file_name, hash|
    file_name_new = gl_suffix_filename(file_name, DateTime.now.strftime("_%m-%d-%y-%k%M%S-%L"))
    File.write(file_name_new, JSON.dump(hash)) 
end
