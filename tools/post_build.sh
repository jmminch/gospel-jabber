#!/bin/bash
TOP_DIR="$(git rev-parse --show-toplevel)"

if [ $? -ne 0 ]; then
  echo "Couldn't determine toplevel dir."
  exit
fi

if [[ ! -d "$TOP_DIR/build" ]]; then
  echo "Some expected directories missing."
  exit 1
fi

# Insert a build ID into the about... data
BUILD_ID=$(date +"%y%m%d")
sed -i "s/@BUILD@/$BUILD_ID/" build/index.html
