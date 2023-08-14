#!/bin/bash

# This script will output the first GPS reading it can get and then terminate

gpspipe -w -n 6 | fgrep TPV| while read LINE
do
  LATITUDE=$(echo $LINE | jq '.lat')
  LONGITUDE=$(echo $LINE | jq '.lon')

  # If the latitude and longitude are not null, then print them and break the loop
  if [ ! -z $LATITUDE ] && [ ! -z $LONGITUDE ] && [ $LATITUDE != null ] && [ $LONGITUDE != null ]
  then
    echo "$LATITUDE,$LONGITUDE"
    break
  fi
done

exit 0
