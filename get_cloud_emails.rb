require 'rest-client'
require 'json'
require 'csv'

load 'cls_helpers.rb'

# # # # # # # # # # # # #
#                       #
#   CLOUD EMAILS TOOL   #
#                       #
# # # # # # # # # # # # # 
# 
# Instructions:
#
# 1. Change the value of the cls_urn variable on line 141 to match the CLS you are wanting to export emails for
# 2. Save your changes
# 3. Open Terminal
# 4. Navigate to the folder that the get_cloud_emails.rb file is saved
# 5. Type the following command in your terminal window: ruby get_cloud_emails.rb
# 6. You're done! A confirmation message should display on the screen.
# 
# Note: Any new executions of this script will overwrite the specified client's data in their emails csv. 
# 
#

class EmailsHolder

  attr_accessor :loc_name
  attr_accessor :loc_internal_name
  attr_accessor :loc_urn
  attr_accessor :loc_hub_emails
  attr_accessor :loc_cls_emails
  attr_accessor :loc_status

  def initialize(name, internal_name, urn, emails, status)
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

# get client_urn
def get_client_urn(base_url)
  client_urn = ""
  response = get_response base_url
  data = get_data response, base_url
  client_urn = data["configurable_attributes"][0]["client_urn"]
  return client_urn
end

# Build our emails objects with hub data
# add to our objects with cls data
# export data to csv
def get_emails(client_urn, cls_url)
  # array used for data export
  emails_arr = []
  
  # get data from the hub api
  hub_url = "http://hub.g5dxm.com/clients/#{client_urn}.json"
  hub_response = get_response hub_url
  hub_data = get_data hub_response, hub_url
  
  # get data from cls api
  cls_response = get_response cls_url
  cls_data = get_data cls_response, cls_url
  
  # build objects with hub data
  hub_data["client"]["locations"].each do |loc|
  
    # grab locations that are not deleted or suspended
    email_obj = EmailsHolder.new(loc["name"], loc["internal_branded_name"], loc["urn"], loc["email"], loc["status"])
    
    # variables for matching cls data
    my_string = ""
    match_val = -1
    cls_emails = ""
    
    # add cls data to existing objects
    cls_data["configurable_attributes"].each do |item|
      # add to existing object if location urns are the same
      if item["category"] == "Location" && item["location_urn"] == email_obj.loc_urn && item["field"] == "to_email"
        # only push values that are emails
        my_string = item["value"]
        match_val = /@/ =~ my_string
        if match_val == nil
          # puts "nil: not a valid value"
        elsif match_val >= 0
          email_obj.add_cls_email(item["value"])
        end
      end
    end
  
    # only push objects that are live or pending status
    if email_obj.loc_status != "Deleted" && email_obj.loc_status != "Suspended"
      emails_arr.push(email_obj)
    end
  end
  
  # run export to csv method
  export_emails "#{client_urn}_cloud_emails.csv", emails_arr
end

# create local csv
# export data to csv
def export_emails(file_name, arr)
  csv_headers = ["Location Name:", "Internal Branded Name:", "CLS emails:", "Hub Emails:"]
  CSV.open(file_name, "wb") do |csv|
    csv << csv_headers
  end
  i = 0
  while i < arr.length
    CSV.open(file_name, "a+") do |csv|
      formatted = []
      formatted.push(arr[i].loc_name, arr[i].loc_internal_name, arr[i].loc_cls_emails, arr[i].loc_hub_emails)
      csv << formatted
      i = i+1
    end
  end
  puts "Emails exported!"
end

# script start
# example cls URN: cls_urn = "g5-cls-1234-name"
cls_urn = "g5-cls-inhx0yfu-the-danger-zon"
cls_url = "https://#{cls_urn}.herokuapp.com/api/v1/configurable_attributes"
puts "Gathering data for #{cls_urn}..."
client_urn = get_client_urn cls_url
get_emails client_urn, cls_url
