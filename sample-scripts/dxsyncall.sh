#!/bin/bash

cd ~/data
for dir in ./*; do
  if [ "$dir" != "./origins" ]; then
    echo "Syncing $dir..."
    cd ~/data
    cd "$dir"
    ~/data/.dxsync.sh . $(basename "$PWD") yes
  fi
done
