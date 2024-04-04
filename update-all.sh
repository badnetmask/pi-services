#!/bin/bash
# This script will check if there are updates for all images,
# and restart the compose if needed.

echo "**"
echo "In all fairness, this script is overkill..."
echo "$ docker-compose pull && docker-compose up -d"
echo "The above commands do the same thing, with much less effort..."
echo "**

rc=0
do_update=0

for image in $(awk '/image: /{gsub("\"","");print $2}' docker-compose.yml); do
  pull_status=$(docker pull ${image} | grep Status)
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "${image}: Docker pull appear to have failed. It's better to not continue..."
    break
  fi
  if [ "$pull_status" == *"Downloaded newer image for"* ]; then
    echo "${image}: has been updated. Will try to restart everything."
    do_update=1
  fi
done

if [ $rc -eq 0 ] && [ $do_update -eq 1 ]; then
  # restart everything only if all pull succeeded, and at least one image was updated
  docker-compose down && docker-compose rm && docker-compose up -d
elif [ $rc -ne 0 ]; then
  exit $rc
else
  echo "No updates were detected. Nothing to do."
fi
