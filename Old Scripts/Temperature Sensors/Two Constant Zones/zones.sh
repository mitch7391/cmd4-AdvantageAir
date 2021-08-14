#!/bin/bash

# IP address
ip="192.168.0.173:2025"

if [ "$1" = "Get" ]; then
  case "$3" in
    # Gets the current temperature
    CurrentTemperature )
      curl -s http://$ip/getSystemData | jq '.aircons.ac1.zones.'"$4"'.measuredTemp'
    ;;

    # Temperature Sensor Fault Status. Faulted if returned value is greater than 0.
    StatusFault )
      if  [ "$(curl -s http://$ip/getSystemData | jq '.aircons.ac1.zones.'"$4"'.error')" = '0' ]; then
        echo 0
      else
        echo 1
      fi
    ;;

    # Get zone open/closed status
    On )
      if [ "$(curl -s http://$ip/getSystemData | jq '.aircons.ac1.zones.'"$4"'.state')" = '"open"' ]; then
        echo 1
      else
        echo 0
      fi
    ;;
  esac
fi

if [ "$1" = "Set" ]; then
  case "$3" in
    # Set zone to open/close.
    On )
      if [ "$4" = "1" ]; then
        curl -g http://$ip/setAircon?json={"ac1":{"zones":{"$5":{"state":"open"}}}}
      else
        curl -g http://$ip/setAircon?json={"ac1":{"zones":{"$5":{"state":"close"}}}}
      fi
    ;;
  esac
fi

exit 0
