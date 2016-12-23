require 'json'

# read from file, parse json data
filename = "heroku_results.json"
file = File.read(filename)
data_hash = JSON.parse(file)

# containers for holding app names
on_g5_emails = []
off_g5_emails = []

data_hash.each do |item|
  if item[1].has_key?("G5_EMAILS_URL")
   on_g5_emails << item[1]["HEROKU_APP_NAME"]
  else 
    off_g5_emails << item[1]["HEROKU_APP_NAME"]
  end
end

# display data in terminal
puts "CLS' on G5 Emails: #{on_g5_emails}"
puts "Count: #{on_g5_emails.count}"
puts "***************************************************"
puts "CLS' off G5 Emails #{off_g5_emails}"
puts "Count: #{off_g5_emails.count}"