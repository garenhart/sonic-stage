#######################
# lib-io.rb
# input/output library
# author: Garen H.
#######################

# configuration folder path
# configPath = get(:sp_path) + "live-impro\\sonic-pi-open-stage-control\\config\\" #path for config files

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
define :writeJSON do |file_name, hash|
    File.write(file_name, JSON.pretty_generate(hash, indent: "    ")) 
end

# create unique name based on current date-time and save hash into it
define :write_unique_JSON do |file_name, hash|
    file_name_new = suffix_filename(file_name, DateTime.now.strftime("_%m-%d-%y-%k%M%S-%L"))
    # File.write(file_name_new, JSON.pretty_generate(hash, indent: "    "))
    File.write(file_name_new, JSON.pretty_generate(hash, array_nl: "")) # array_nl: "" puts array in one string, but still retains appropriate indentation which makes in worse
end
