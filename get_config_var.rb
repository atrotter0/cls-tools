require 'json'

# 1) Run get_heroku_json.sh
# 2) Paste terminal output into heroku_results.json
# 3) Remove last ',' from before the last '}' in heroku_results.json
# 4) Edit the key variable on Line 13 for the config var you want to obtain from the Heroku app list
# 5) Run get_config_var.rb

# read from file, parse json data
filename = "heroku_results.json"
file = File.read(filename)
data_hash = JSON.parse(file)
key = "SEND_VENDOR_ERROR_EMAILS"
#key = "G5_EMAILS_URL"

# containers for holding app names
config_var_set = []
config_var_unset = []

data_hash.each do |item|
  if item[1].has_key?(key)
    app_name = item[0]
    config_var_set << app_name
    #config_var_set << item[1][key]
  else
    app_name = item[0]
    config_var_unset << app_name
  end
end

# display data in terminal
puts "CLSs with config var set- "
puts "Count: #{config_var_set.count}"
puts ""
puts "CLSs without config var set- "
puts "Count: #{config_var_unset.count}"
puts ""

# print out data arrays
puts "Config var set:"
# puts "(App name and #{key} => value)"
config_var_set.each do |cls|
  puts cls
end

puts ""
puts "Config var not set:"
# puts "App name"
config_var_unset.each do |cls|
  puts cls
end
