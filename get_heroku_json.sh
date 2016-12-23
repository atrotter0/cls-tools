#!/bin/sh

# file to read data from
filename="cls-test-list.txt"

# add json formatting at top and bottom of file
echo {
while IFS= read -r line; do
  cls_url=$line
  echo \"$line\":
  curl -n https://api.heroku.com/apps/$cls_url/config-vars \
  -H "Accept: application/vnd.heroku+json; version=3"
  sleep 1s
  echo ,
done < "$filename"
echo }