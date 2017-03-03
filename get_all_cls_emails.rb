require 'rest-client'
require 'json'
require 'csv'

load 'cls_helpers.rb'

# # # # # # # # # # # # # # # #
#                             #
#   GET ALL CLS EMAILS TOOL   #
#                             #
# # # # # # # # # # # # # # # #
# 
# Instructions:
#
# 1. You will need an export from Wrangler with the current list of CLS'
# 2. Modify the file name on line 147 to match the name of your CLS list
# 3. Save your changes
# 4. Open Terminal
# 5. Navigate to the folder that the get_all_cls_emails.rb file is saved
# 6. Type the following command in your terminal window: ruby get_all_cls_emails.rb
# 7. Monitor your terminal as each CLS is processed
# 8. A message stating "Emails exported!" should display on the screen when the script has completed
# 
# Note: Any new executions of this script will overwrite the csv export. 
# 
#

class EmailsHolder

  attr_accessor :client_name, :loc_name, :loc_internal_name, :loc_urn, :loc_hub_emails, :loc_cls_emails, :loc_status

  def initialize(client, name, internal_name, urn, emails, status)
    @client_name = client
    @loc_name = name
    @loc_internal_name = internal_name
    @loc_urn = urn
    @loc_hub_emails = emails
    @loc_cls_emails = ""
    @loc_status = status
  end

  def display
    puts "Name: #{@loc_name}"
    puts "Internal Name: #{@loc_internal_name}"
    puts "URN: #{@loc_urn}"
    puts "Hub Emails: #{@loc_hub_emails}"
    puts "CLS Emails: #{@loc_cls_emails}"
    puts "Status: #{@loc_status}"
  end

  def add_cls_email(email_val)
    @loc_cls_emails = @loc_cls_emails + " " + email_val
  end

end

def build_cls_list(file_name, arr)
  file = File.open(file_name, "r")
  while !file.eof?
    line = file.readline.chomp
    arr.push(line)
  end
  file.close
end

def get_client_urn(base_url)
  client_urn = ""
  response = get_response base_url
  if response
    data = get_data response, base_url
    client_urn = data["configurable_attributes"][0]["client_urn"]
    return client_urn
  end
end

def generate_emails_list(cls_list, emails_container)
  cls_list.each do |line|
    cls_urn = line
    cls_url = "https://#{cls_urn}.herokuapp.com/api/v1/configurable_attributes"
    puts "Gathering data for #{cls_urn}..."
    client_urn = get_client_urn cls_url
    if client_urn != nil
      get_emails client_urn, cls_url, emails_container
    end
  end
end

def get_emails(client_urn, cls_url, arr)
  # array used for data export
  emails_arr = arr
  
  # get data from the hub api
  hub_url = "http://hub.g5dxm.com/clients/#{client_urn}.json"
  hub_response = get_response hub_url
  if hub_response
    hub_data = get_data hub_response, hub_url
    client_name = hub_data["client"]["name"]
  
    # get data from cls api
    cls_response = get_response cls_url
    cls_data = get_data cls_response, cls_url
    
    # build objects with hub data
    hub_data["client"]["locations"].each do |loc|
    
      # grab locations that are not deleted or suspended
      email_obj = EmailsHolder.new(client_name, loc["name"], loc["internal_branded_name"], loc["urn"], loc["email"], loc["status"])
      
      # add cls data to existing objects
      cls_data["configurable_attributes"].each do |item|
        # add to existing object if location urns are the same
        if item["category"] == "Location" && item["location_urn"] == email_obj.loc_urn && item["field"] == "to_email"
          email_obj.add_cls_email(item["value"]) if item["value"].include? "@"
        end
      end
      
      # only push objects that are live or pending status
      if email_obj.loc_status != "Deleted" && email_obj.loc_status != "Suspended"
        emails_arr.push(email_obj)
      end
    end
  end
end

# create local csv
# export data to csv
def export_emails(file_name, arr)
  csv_headers = ["Client:", "Location:", "Internal Branded Name:", "CLS emails:", "Hub Emails:"]
  CSV.open(file_name, "wb") do |csv|
    csv << csv_headers
  end
  i = 0
  while i < arr.length
    CSV.open(file_name, "a+") do |csv|
      formatted = []
      formatted.push(arr[i].client_name, arr[i].loc_name, arr[i].loc_internal_name, arr[i].loc_cls_emails, arr[i].loc_hub_emails)
      csv << formatted
      i = i+1
    end
  end
  puts "Emails exported!"
end

# script start
emails_container = []
cls_list = []
cls_file = "cls-list.txt"
build_cls_list cls_file, cls_list
generate_emails_list cls_list, emails_container
export_emails "all-cls-emails.csv", emails_container
