#######################
# lib-io.rb
# input/output library
# author: Garen H.
#######################

# configuration folder path
# configPath = get(:sp_path) + "live-impro\\sonic-pi-open-stage-control\\config\\" #path for config files

define :initJSON do |file_name|
    data = readJSON(file_name)
    return ensure_defaults(data)
end

define :ensure_defaults do |data|
    data = ensure_adsr(data)
    return data
end

define :ensure_adsr do |data|
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
    if data["drums"]["kick"]["adsr"] == nil
        data["drums"]["kick"]["adsr"] = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]
    end
    if data["drums"]["snare"]["adsr"] == nil
        data["drums"]["snare"]["adsr"] = [0.0, 1.0, 0.1, 0.9, 0.2, 0.9, 1.0, 0.0]
    end
    return data
end

# read from JSON file and return parsed hash
define :readJSON do |file_name|
    file = File.read(file_name) 
    return JSON.parse(file)
    # return  MultiJson.load(file) # this works as well
end

# insert suffix into file name before extension
define :suffix_filename do |file_name, suffix|
    extension = File.extname(file_name)
    file_name.reverse.sub(extension.reverse, ("#{suffix}#{extension}").reverse).reverse
end

# save hash into JSON file
define :writeJSON_1 do |file_name, hash|
    File.write(file_name, JSON.pretty_generate(hash, indent: "    ")) 
end

# create unique name based on current date-time and save hash into it
define :write_JSON_2 do |file_name, hash|
    file_name_new = suffix_filename(file_name, DateTime.now.strftime("_%m-%d-%y-%k%M%S-%L"))
    # File.write(file_name_new, JSON.pretty_generate(hash, indent: "    "))
    File.write(file_name_new, JSON.pretty_generate(hash, array_nl: "")) # array_nl: "" puts array in one string, but still retains appropriate indentation which makes in worse
end

# generate a unique file name based on file_name
# by appending a suffix with next available number (at least 2 digits)
define :unique_filename do |file_name|
    extension = File.extname(file_name)
    file_name_base = file_name.reverse.sub(extension.reverse, "".reverse).reverse
    puts "file_name_base", file_name_base
    file_name_base = file_name_base.split("_").first
    file_name_new = file_name_base + extension
    puts "file_name_new", file_name_new
    i = 0
    while File.exist?(file_name_new)
        i += 1
        file_name_new = "#{file_name_base}_#{i.to_s.rjust(2, '0')}#{extension}"
    end
    puts "file_name_new", file_name_new
    return file_name_new
end

# save hash into JSON file with unique name
# with error handling
# and return the name
define :write_unique_JSON do |file_name, hash|    
    file_name_new = unique_filename(file_name)
    File.write(file_name_new, JSON.pretty_generate(hash, array_nl: "")) # array_nl: "" puts array in one string, but still retains appropriate indentation which makes in worse
    return file_name_only file_name_new
end

# return file name without path
define :file_name_only do |file_name|
    return File.basename(file_name)  
end
