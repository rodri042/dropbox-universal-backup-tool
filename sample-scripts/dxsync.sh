#!/bin/bash

if [[ "$3" == "yes" ]] ; then
  OPTION="--yes"
else
  OPTION=""
fi

~/data/scripts/dxubt/dxubt.js --from="$1" --to="/HDD/data/$2" --ignore='["/node_modules", "/bower_components", ".git", ".tmp"]' --token=$SECRET_TOKEN $OPTION
