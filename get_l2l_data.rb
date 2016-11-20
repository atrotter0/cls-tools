require 'rest-client'
require 'json'
require 'csv'

load 'cls_helpers.rb'

# # # # # # # # # # # # #
#                       #
#    L2L FINDER TOOL    #
#                       #
# # # # # # # # # # # # # 
# 
# Instructions:
#
# 1. You will need an export from Wrangler with the current list of CLSs
# 2. Modify the file name on line 129 to match the filename of your CLS list
# 3. Save your changes
# 4. Open Terminal
# 5. Navigate to the folder where the get_l2l_data.rb script is saved
# 6. Type the following command in your terminal window: ruby get_l2l_data.rb
# 7. This may take awhile if iterating through all CLSs. A confirmation message should display on the screen when the task is complete.
# 
# Note: Any new executions of this script will overwrite the cls-l2l-list csv. 
# 
#

class LeadToLeaseData

  attr_accessor :name
  attr_accessor :loc_count
  attr_accessor :customer_count
  attr_accessor :count

  def initialize(name)
    @name = name
    @loc_count = 0
    @customer_count = 0
    @count = 0
  end

  def get_count
    @count = @loc_count + @customer_count
    return @count
  end

  def add_location_count
    @loc_count = @loc_count + 1
  end

  def add_customer_count
    @customer_count = @customer_count + 1
  end

end

# build arr from our cls list
def build_cls_list(file_name, arr)
  file = File.open(file_name, "r")
  while !file.eof?
    line = file.readline.chomp
    arr.push(line)
  end
  file.close
end

# export l2l arr of objects to csv
def export_to_csv(file_name, arr)
  puts "Exporting list..."
  csv_headers = ["CLS URN:", "Lead2Lease Count:"]
  CSV.open(file_name, "wb") do |csv|
    csv << csv_headers
  end
  i = 0
  while i < arr.length
    CSV.open(file_name, "a+") do |csv|
      formatted = []
      if arr[i].get_count > 0
        formatted.push(arr[i].name, arr[i].get_count)
        csv << formatted
      end
    end
  i = i+1
  end
  puts "Lead2Lease list exported!"
end

# run l2l finder
def lead_to_lease_finder(arr)
  container = []
  arr.each do |cls|
    cls_url = "https://#{cls}.herokuapp.com/api/v1/configurable_attributes"
    cls_response = get_response cls_url

    if cls_response == true
      cls_data = get_data cls_response, cls_url
      lead_to_lease_data = LeadToLeaseData.new(cls)
      puts "Checking #{cls}..."

      # iterate through data and count l2l emails
      cls_data["configurable_attributes"].each do |item|
        if item["category"] == "Location" && item["field"] == "to_email"
          if item["value"].include? "lead2lease"
            lead_to_lease_data.add_location_count
          end
        elsif item["category"] == "Customer" && item["field"] == "reply_to_email"
          if item["value"].include? "lead2lease"
            lead_to_lease_data.add_customer_count
          end
        end
      end

      # get total l2l email count for current cls and push obj into our container
      count = lead_to_lease_data.get_count
      if count > 0
        puts "#{count} lead2lease emails found!"
        container.push(lead_to_lease_data)
      else
        puts "0 lead2lease emails found." 
      end
    end
  end

  # export data to csv
  export_to_csv "cls-l2l-list.csv", container
end

# script start
puts "Gathering data..."
file = "cls-list.txt"
cls_list = []
build_cls_list file, cls_list
lead_to_lease_finder cls_list
