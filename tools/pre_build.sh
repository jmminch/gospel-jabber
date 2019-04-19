#!/bin/bash
TOP_DIR="$(git rev-parse --show-toplevel)"

if [ $? -ne 0 ]; then
  echo "Couldn't determine toplevel dir."
  exit
fi

if [[ ! -d "$TOP_DIR/data" || ! -d "$TOP_DIR/web" ]]; then
  echo "Some expected directories missing."
  exit 1
fi

# Build the phrases.dart file
cd "$TOP_DIR"

./tools/gen_phrases_dart.pl > web/phrases.dart
