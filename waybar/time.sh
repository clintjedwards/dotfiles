#!/bin/bash

# Function to add suffix to day
addSuffix() {
  case "$(date +%-d)" in
    1|21|31) echo $(date +%-d)"st" ;;
    2|22) echo $(date +%-d)"nd" ;;
    3|23) echo $(date +%-d)"rd" ;;
    *) echo $(date +%-d)"th" ;;
  esac
}

# Get the date in required format
DATE=$(date +"%A, %B $(addSuffix) %I:%M:%S %P")

echo $DATE
