require 'rest-client'
require 'json'
require 'csv'

# # # # # # # # # # # # #
# 											#
#   CLS OVERRIDES TOOL  #
#     									#
# # # # # # # # # # # # # 
# 
# Instructions:
#
# 1. Change the value of the cls_urn variable on line 313 to match the CLS you are wanting to export emails for
# 2. Save your changes
# 3. Open Terminal
# 4. Navigate to the folder that the cls_overrides.rb file is saved
# 5. Type the following command in your terminal window: ruby cls_overrides.rb
# 6. You're done! A confirmation message should display on the screen.
# 
# Note: Any new executions of this script will overwrite the specified client's data in their overrides csv. 
# 
#

class Overrides

	def initialize(name, internal_name, urn, status)
		@name = name
		@internal_name = internal_name
		@urn = urn
		@status = status
		@category = ""
		@subject = ""
		@from_name = ""
		@from_email = ""
		@to_name = ""
		@to_email = ""
		@greeting = ""
		@header_img = ""
		@header_bg = ""
		@body_style = ""
	end

	def display
		puts "Name: #{@name}"
		puts "Internal Name: #{@internal_name}"
		puts "URN: #{@urn}"
		puts "Category: #{@category}"
		puts "subject: #{@subject}"
		puts "from_name: #{@from_name}"
		puts "from_email: #{@from_email}"
		puts "to_name: #{@to_name}"
		puts "to_email: #{@to_email}"
		puts "greeting: #{@greeting}"
		puts "header_img: #{@header_img}"
		puts "header_bg: #{@header_bg}"
		puts "body_style: #{@body_style}"
	end

	# getters 
	def get_urn
		return @urn
	end

	def get_name
		return @name
	end

	def get_internal_name
		return @internal_name
	end

	def get_status
		return @status
	end

	def get_category
		return @category
	end

	def get_subject
		return @subject
	end

	def get_from_name
		return @from_name
	end

	def get_from_email
		return @from_email
	end

	def get_to_name
		return @to_name
	end

	def get_to_email
		return @to_email
	end

	def get_greeting
		return @greeting
	end

	def get_header_img
		return @header_img
	end

	def get_header_bg
		return @header_bg
	end

	def get_body_style
		return @body_style
	end

	# setters
	def add_category(value)
		@category = value
	end

	def add_subject(value)
		@subject = value
	end

	def add_from_name(value)
		@from_name = value
	end

	def add_from_email(value)
		@from_email = value
	end

	def add_to_name(value)
		@to_name = value
	end	

	def add_to_email(value)
		@to_email = value
	end	

	def add_header_img(value)
		@header_img = value
	end

	def add_header_bg(value)
		@header_bg = value
	end

	def add_body_style(value)
		@body_style = value
	end

	def add_greeting(value)
		@greeting = value
	end

end

# Get response from the cls API
# Set response flag and return response flag to trigger next method
def get_response(url)
	res_flag = false
	response = RestClient.get(url){|response, request, result| response 
		if response.code != 200
			puts response.code
			res_flag = true
			puts "Skipped due to #{response.code}"
		end
	}
	return res_flag
end

# Get and return cls data if response is valid
def get_data(flag, url)
	data = ""
	response = 0
	if flag == false
		response = RestClient.get(url)
		data = JSON.load response
	end
	return data
end

# get client_urn
def get_client_urn(base_url)
	client_urn = ""
	response = get_response base_url
	data = get_data response, base_url
	client_urn = data["configurable_attributes"][0]["client_urn"]
	return client_urn
end

# Build our overrides object with hub data
# add to our object with cls data
# export data to csv
def build_object(client_urn, cls_url)
	# array used for data export
	loc_overrides_arr = []
	cust_overrides_arr = []
	# get data from the hub api
	hub_url = "http://hub.g5dxm.com/clients/#{client_urn}.json"
	hub_response = get_response hub_url
	hub_data = get_data hub_response, hub_url
	# get data from cls api
	cls_response = get_response cls_url
	cls_data = get_data cls_response, cls_url
	# build objects with hub data
	hub_data["client"]["locations"].each do |loc|
		loc_overrides_obj = Overrides.new(loc["name"], loc["internal_branded_name"], loc["urn"], loc["status"])
		cust_overrides_obj = Overrides.new(loc["name"], loc["internal_branded_name"], loc["urn"], loc["status"])
		# add cls API override data to existing objects
		cls_data["configurable_attributes"].each do |item|
			# seperate by category
			if item["category"] == "Location"
				# run get_overrides with specific category
				loc_overrides_obj = get_overrides item, loc_overrides_obj, "Location", loc_overrides_arr	
			elsif item["category"] == "Customer"
				cust_overrides_obj = get_overrides item, cust_overrides_obj, "Customer", cust_overrides_arr
			end
		end
		# push override objs to arrays
		if loc_overrides_obj.get_status != "Deleted" && loc_overrides_obj.get_status != "Suspended" && cust_overrides_obj.get_status != "Deleted" && cust_overrides_obj.get_status != "Suspended"
			loc_overrides_arr.push(loc_overrides_obj)
			cust_overrides_arr.push(cust_overrides_obj)
		end
	end
	# run export to csv method
	export_overrides "#{client_urn}_cls_overrides.csv", loc_overrides_arr, cust_overrides_arr
	puts "Overrides exported!"
end

# get overrides for specific emailer category
# add values to object if they match all cls API values
# return object
def get_overrides(item, obj, category, arr)
	# location overrides
	if category == "Location"
		obj.add_category(item["category"])
		if item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "subject"
			obj.add_subject(item["value"])
		elsif item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "from_name"
			obj.add_from_name(item["value"])
		elsif item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "from_email"
			obj.add_from_email(item["value"])
		elsif item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "to_name"
			obj.add_to_name(item["value"])
		# user get_cloud_emails.rb for comprehensive email list.
		# elsif item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "to_email"
		# 	obj.add_to_email(item["value"])
		elsif item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "greeting_paragraph"
			obj.add_greeting(item["value"])
		elsif item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "header_image_url"
			obj.add_header_img(item["value"])
		elsif item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "header_background_color"
			obj.add_header_bg(item["value"])
		elsif item["category"] == "Location" && item["location_urn"] == obj.get_urn && item["field"] == "body_style"
			obj.add_body_style(item["value"])
		end
	# customer overrides
	else
		obj.add_category(item["category"])
		if item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "subject"
			obj.add_subject(item["value"])
		elsif item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "from_name"
			obj.add_from_name(item["value"])
		elsif item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "from_email"
			obj.add_from_email(item["value"])
		elsif item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "to_name"
			obj.add_to_name(item["value"])
		elsif item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "reply_to_email"
			obj.add_to_email(item["value"])
		elsif item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "greeting_paragraph"
			obj.add_greeting(item["value"])
		elsif item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "header_image_url"
			obj.add_header_img(item["value"])
		elsif item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "header_background_color"
			obj.add_header_bg(item["value"])
		elsif item["category"] == "Customer" && item["location_urn"] == obj.get_urn && item["field"] == "body_style"
			obj.add_body_style(item["value"])
		end
	end
	return obj
end

# create local csv
# export data to csv
def export_overrides(file_name, arr_1, arr_2)
	csv_headers = ["Location Name:", "Internal Branded Name:", "Category:", "subject:", "from_name:", "from_email:", "to_name:", "to_email:", "greeting:", "header_img", "header_bg:", "body_style:"]
	CSV.open(file_name, "wb") do |csv|
		csv << csv_headers
	end
	# export overrides to csv
	export_category file_name, arr_1
	export_category file_name, arr_2
end

# open local csv
# loop through category array, push values to csv
def export_category(file_name, arr)
	i = 0
	while i < arr.length
		CSV.open(file_name, "a+") do |csv|
			formatted = []
			formatted.push(arr[i].get_name, arr[i].get_internal_name, arr[i].get_category, arr[i].get_subject, arr[i].get_from_name, arr[i].get_from_email, arr[i].get_to_name, arr[i].get_to_email, arr[i].get_greeting, arr[i].get_header_img, arr[i].get_body_style)
			csv << formatted
			i = i+1
		end
	end
end

# script start
# example cls URN: cls_urn = "g5-cls-ifu2jcq3-pensam-capital"
cls_urn = "g5-cls-1t2d31r8-berkshire-comm"
cls_url = "https://#{cls_urn}.herokuapp.com/api/v1/configurable_attributes"
puts "Gathering data for #{cls_urn}..."
client_urn = get_client_urn cls_url
build_object client_urn, cls_url
