#!/bin/bash
# Example script to check online status
if ping -c 1 google.com &>/dev/null; then
  echo "ok"
else
  echo "off"
fi
