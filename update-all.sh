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

echo "Checking for image updates using ./docker-compose.yml"
for image in $(awk '!/#/&&/image: /{gsub("\"","");print $2}' docker-compose.yml); do
  echo -n "${image}: "
  pull_status=$(docker pull ${image} | grep Status)
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "Docker pull appear to have failed. It's better to not continue..."
    break
  fi
  if [ ! -z "echo '$pull_status' | grep 'Downloaded newer image for'" ]; then
    echo "Image updated."
    do_update=1
  else
    echo "No updates available."
  fi
done

if [ $rc -eq 0 ] && [ $do_update -eq 1 ]; then
  # restart everything only if all pull succeeded, and at least one image was updated
  echo "At least one image was updated. Attempting to restart the compose."
  docker-compose down && docker-compose rm && docker-compose up -d
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "Restart completed."
  else
    echo "Failed to restart."
  fi
elif [ $rc -ne 0 ]; then
  exit $rc
else
  echo "No updates were detected. Nothing to do."
fi
