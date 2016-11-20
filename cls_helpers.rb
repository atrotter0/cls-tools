# get cls response
def get_response(url)
  flag = true
  response = RestClient.get(url){|response, request, result| response 
    if response.code != 200
      flag = false
      puts "Skipped #{url} (#{response.code})"
    end
  }
  return flag
end

# Get and return cls data if response is valid
def get_data(flag, url)
  data = ""
  response = 0
  if flag == true
    response = RestClient.get(url)
    data = JSON.load response
  end
  return data
end