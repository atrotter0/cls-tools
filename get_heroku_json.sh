#!/bin/sh

# file to read data from
filename="cls-list.txt"

# json formatting
echo {
while IFS= read -r line; do
  cls_url=$line
  # json formatting
  echo \"$line\":
  curl -n https://api.heroku.com/apps/$cls_url/config-vars \
  -H "Accept: application/vnd.heroku+json; version=3"
  sleep 1s
  # json formatting
  echo ,
done < "$filename"
# json formatting
echo }