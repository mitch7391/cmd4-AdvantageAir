#!/bin/bash

######################################################################################################################################################################
######################################################################################################################################################################
#                                                                                                                                                                    #
# A massive thank you to John Talbot of homebridge-cmd4 for all his work on improving this shell script and the improvements to homebridge-cmd4 to cater further to  #
# the Advantage Air controller and all of it's Homebridge users!                                                                                                     #
#                                                                                                                                                                    #
# A massive thanks also to @uswong for his ideas and contributions to adding 'rotationSpeed' to the Fan accessory and a "linkedType" 'Fan Speed' to the Thermostat   #
# accessory for speed control (low/medium/high/auto). I am very pleased with the work and I think a lot of users will be too!                                        #
#                                                                                                                                                                    #
######################################################################################################################################################################
######################################################################################################################################################################

# Lets be explicit
typeset -i a argSTART argEND

#
# Passed in required Args
#
argEND=$#
IP=""
device=""
io=""
characteristic=""
value="1"

#
# Global returned data
#
myAirData=""
jqResult=""
rc=1

#
# For optional args and arg parsing
#

# Default zone
zone=""
zoneSpecified=false
argSTART=4
logErrors=true
noSensors=false
fanSpeed=false
fspeed="low"
# By default selfTest is off
selfTest="TEST_OFF"


function showHelp()
{
   local rc="$1"
   cat <<'   HELP_EOF'

   Usage:
     AdvAir.sh Get < AccessoryName > < characteristic > [ Options ]
   or
     AdvAir.sh Set < AccessoryName > < characteristic > < value > [ Options ]

   Where Options maybe any of the following in any order:
     z01, z02, z03 ...  The zone to Set or Query
     XXX.XXX.XXX.XXX    The IP address of the AirCon to talk to
     noSensors          If you do not have any sensors
     fanSpeed           If the accessory is used to control the fan speed

   Additional test options to the above are:
     TEST_OFF           The default
     TEST_ON            For npm run test
     TEST_CMD4          In ones config.json and dev test data must be available.

   HELP_EOF
   exit "$rc"
}

function logError()
{
   if [ "$logErrors" != true ]; then
      return
   fi

   local comment="$1"
   local rc="$2"
   local result="$3"
   local data1="$4"
   local data2="$5"

   local dt
   dt=$(date +%s)
   local fileName="/tmp/AirconError-$dt.txt"

   { echo "$io $device $characteristic"
     echo "${comment}"
     echo "return code: $rc"
     echo "result: $result"
     echo "data1: $data1"
     echo "data2: $data2"
   } > "$fileName"
}

function queryAirCon()
{
   local url="$1"
   local exitOnFail="$2"
   local iteration="$3"

   # This script uses a loop instead of the curl retry options because the
   # Aircon will not return all the data when it is busy with a write operation.

   # --max-time 2        (how long in seconds EACH retry can take )
   # --connect-timeout 2 (Amount of sevonds in connevtion phase )
   # --fail              (Exit with rc=22 instead of outputting http connection error document )
   # -g                  (This option switches off the "URL globbing parser". When you set this option,
   #                      you can specify URLs that contain the letters {}[] without having them being
   #                      interpreted by curl itself.
   # -s, --silent        (Silent or quiet mode. Don't show progress meter or error messages. Makes Curl
   #                      mute. It will still output the data you ask for, potentially even to the
   #                      terminal/stdout unless you redirect it.
   # --show-error        (Show error (to stderr) even when -s is used. DO NOT USE
   #                      Cmd4 will get to stderr, "curl failed, rc=1" which is annoying


   # Updates global variable myAirData
   if [ "$selfTest" = "TEST_OFF" ]; then
      myAirData=$( curl --max-time 2 --fail --connect-timeout 2 -s -g "$url" )
      rc=$?
   else
      myAirData=$( cat "./data/getSystemData.txt${iteration}" )
      rc=$?
      # For Testing, you can compare whats sent
      if [ "$io" = "Set" ]; then
         echo "Setting url: $url";
      fi
   fi

   if [ "$rc" != "0" ]; then
      if [ "$exitOnFail" = "1" ]; then
         # The result cannot be trusted with a bad return code
         # Do not output to stderr as this defeats the purpose
         # of squashing error messages
         logError "curl failed" "$rc" "$myAirData" "$url" ""
         exit $rc
      fi
   fi
}

function parseMyAirDataWithJq()
{
   local jqPath="$1"
   local exitOnFail="$2"

   # Understanding jq options
   # -e                  (Upon bad data, exit with return code )

   # Updates global variable jqResult
   jqResult=$(echo "$myAirData" | jq -e "$jqPath")
   rc=$?

   if [ "$rc" != "0" ]; then
      if [ "$exitOnFail" = "1" ]; then
         # The result cannot be trusted with a bad return code
         # Do not output to stderr as this defeats the purpose
         # of squashing error messages
         logError "jq failed" "$rc" "$jqResult" "$myAirData" "$jqPath"
         exit $rc
      fi
   fi
}

function queryAndParseAirCon()
{
   local url="$1"
   local jqPath="$2"

   # Try 5 times, the last returning the error found.
   for i in 0 1 2 3 4
   do
      if [ "$selfTest" = "TEST_ON" ]; then
         echo "Try $i"
      fi

      local exitOnFail="0"
      if [ "$i" = "4" ]; then
         exitOnFail="1"
      fi
      # Updates global variable myAirData
      queryAirCon "$url" "$exitOnFail" "$i"

      if [ "$rc" = "0" ]; then
         # Updates global variable jqResult
         parseMyAirDataWithJq "$jqPath" "$exitOnFail"

         if [ "$rc" = "0" ]; then
            break
         else
            sleep 0.3
         fi
      else
         sleep 0.3
      fi

   done
}

# main starts here

if [ $argEND -le 1 ]; then
   showHelp 199
fi

if [ $argEND -ge 1 ]; then
   io=$1
   if [ $argEND -ge 2 ]; then
       device=$2
   else
      echo "Error - No device given for io: ${io}"
      exit 1
   fi

   if [ $argEND -ge 3 ]; then
       characteristic=$3
   else
      echo "Error - No Characteristic given for io: ${io} ${device}"
      exit 1
   fi

   if [ "$io" = "Get" ]; then
      argSTART=4
   elif [[ "$io" == "Set" ]]; then
      argSTART=5
      if [ $argEND -ge 4 ]; then
         value=$4
      else
         echo "Error - No value given to Set: ${io}"
         exit 1
      fi
   else
      echo "Error - Invalid io: ${io}"
      exit 1
   fi
fi


# For any unprocessed arguments
if [ $argEND -ge $argSTART ]; then

   # Scan the remaining options
   for (( a=argSTART;a<=argEND;a++ ))
   do
      # convert argument number to its value
      v=${!a}

      optionUnderstood=false

      # Check the actual option against patterns
      case ${v} in
         TEST_OFF)
            # Standard production usage
            selfTest=${v}
            optionUnderstood=true
            # Note: Only bash 4.0 has fallthrough and it's not portable.
            ;;
         TEST_ON)
            # For npm run test
            selfTest=${v}
            optionUnderstood=true
            ;;
         TEST_CMD4)
            # With Cmd4, but using test data. Causes no echo on try
            selfTest=${v}
            optionUnderstood=true
           ;;
         noSensors)
            noSensors=true
            optionUnderstood=true
           ;;
         fanSpeed)
            fanSpeed=true
            optionUnderstood=true
           ;;
         *)
            #
            # See if the option starts with a 'z' for zone
            #
            first="$(printf '%s' "$v" | cut -c1 )"
            if [ "$first" = z ]; then
               zone=${v}
               zoneSpecified=true
               optionUnderstood=true
            fi
            #
            # See if the option is in the format of an IP
            #
            if expr "$v" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
               IP="$v"
               if [ "$selfTest" = "TEST_ON" ]; then
                  echo "Using IP: $v"
               fi
               optionUnderstood=true
            fi

            if [ "$optionUnderstood" = false ]; then
               echo "Unknown Option: ${v}"
               showHelp 1
            fi
       esac
   done
fi


# For "Get" Directives
if [ "$io" = "Get" ]; then

   case "$characteristic" in
      # Gets the current temperature.
      CurrentTemperature )
         if [ "$noSensors" = true ]; then
            # Uses the set temperature as the measured temperature
            # in lieu of having sensors.
            queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.info.setTemp'
         else
            # Updates global variable jqResult
            queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.zones.'"$zone"'.measuredTemp'
         fi

         echo "$jqResult"

         exit 0
      ;;

      # Gets the target temperature.
      TargetTemperature )
         # Updates global variable jqResult
         queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.info.setTemp'

         echo "$jqResult"

         exit 0
      ;;

      # Sets display units to Celsius.
      TemperatureDisplayUnits )
         echo 0

         exit 0
      ;;

      # Makes the target Control Unit state the current Control Unit state.
      TargetHeatingCoolingState | CurrentHeatingCoolingState )
         # Set to Off if the zone is closed or the Control Unit is Off.
         # Updates global variable jqResult
         queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.info.state'

         if [  "$jqResult" = '"off"' ]; then
            echo 0

            exit 0
         else
            # Get the current mode of the Control Unit. Off=0, Heat=1, Cool=2.
            # Updates global variable jqResult
            parseMyAirDataWithJq '.aircons.ac1.info.mode'
            mode="$jqResult"

            case "$mode" in
               '"heat"' )
                  # Thermostat in Heat Mode.
                  echo 1

                  exit 0
               ;;

               '"cool"' )
                  # Thermostat in Cool Mode.
                 echo 2

                 exit 0
               ;;

               '"vent"' )
                  # Fan mode, set Thermostat to Off and Fan to On.
                  echo 0

                  exit 0
               ;;

               '"dry"' )
                  # No support for a dry mode by Apple, set to Off.
                  echo 0

                  exit 0
               ;;

               * )
                  # If anything unexpected is retruned than the above, return value Off.
                  echo 0

                  exit 0
               ;;
            esac
         fi
      ;;

      On )
         if [ $zoneSpecified = false ] && [ $fanSpeed = false ]; then
            # Return value of Off if the zone is closed or the Control Unit is Off.
            # Updates global variable jqResult
            queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.info.state'

            if [  "$jqResult" = '"off"' ]; then
               echo 0

               exit 0
            else
               # Get the current mode of the Control Unit. Fan can only be On or Off; if not Vent, set all other modes to Off.
               # Updates global variable jqResult
               parseMyAirDataWithJq '.aircons.ac1.info.mode'
               mode="$jqResult"

               case "$mode" in
                  '"heat"' )
                     # Fan does not support Heat Mode.
                     echo 0

                     exit 0
                  ;;

                  '"cool"' )
                     # Fan does not support Cool Mode.
                     echo 0

                     exit 0
                  ;;

                  '"vent"' )
                     # Set Fan to On.
                     echo 1

                     exit 0
                  ;;

                  '"dry"' )
                     # Fan does not support Dry Mode.
                     echo 0

                     exit 0
                  ;;

                  * )
                     # If anything unexpected is retruned than the above, set to Off.
                     echo 0

                     exit 0
                  ;;
               esac
            fi
         elif [ $zoneSpecified = true ]; then

            #damper open/closed = Switch on/off = 1/0
            # Change to On just so we can leave it here for now
            # and it will not get called
            # Updates global variable jqResult
            queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.zones.'"$zone"'.state'

            if [ "$jqResult" = '"open"' ]; then
               echo 1

               exit 0
            else
               echo 0

               exit 0
            fi

         elif [ $fanSpeed = true ]; then
            # set the "Fan Speed" accessory to "on" at all time
               echo 1

               exit 0
         fi
      ;;  # End of On

      #Light Bulb service used for controlling damper % open
      Brightness )
         # Updates global variable jqResult
         queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.zones.'"$zone"'.value'

         echo "$jqResult"

         exit 0
      ;;

      # Fan service for controlling fan speed (low, medium and high)
      RotationSpeed )
         # Update the current fan speed
         queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.info.fan'
         if [ $jqResult = '"low"' ]; then
            #25% as low speed
            echo 25

            exit 0
         elif [ $jqResult = '"medium"' ]; then
            #50% as medium speed
            echo 50

            exit 0
         elif [ $jqResult = '"high"' ]; then
            #90% as high speed
            echo 90

            exit 0
         else
            # one other possibility is "autoAA/auto", then echo 100
            echo 100

            exit 0
         fi
      ;;

      #Temp Sensor Fault Status = no fault/fault = 0/1-2
      StatusLowBattery )
         # Updates global variable jqResult
         queryAndParseAirCon "http://$IP:2025/getSystemData" '.aircons.ac1.zones.'"$zone"'.error'

         if [ "$jqResult" = '0' ]; then
            echo 0

            exit 0
         else
            echo 1

            exit 0
         fi
       ;;  # End of StatusLowBattery

   esac
fi

# For "Set" Directives
if [ "$io" = "Set" ]; then

   case "$characteristic" in
      TargetHeatingCoolingState )
         case "$value" in
            0 )
               # Shut Off Control Unit.
               queryAirCon "http://$IP:2025/setAircon?json={ac1:{info:{state:off}}}" "1" "0"

               exit 0
            ;;
            1 )
               # Turn On Control Unit, Set Mode to Heat, Open Current Zone.
               queryAirCon "http://$IP:2025/setAircon?json={ac1:{info:{state:on,mode:heat}}}" "1" "0"

               exit 0
            ;;
            2 )
               # Turn On Control Unit, Set Mode to Cool, Open Current Zone.
               queryAirCon "http://$IP:2025/setAircon?json={ac1:{info:{state:on,mode:cool}}}" "1" "0"

               exit 0
            ;;
         esac
      ;;

      TargetTemperature )
         if [ "$noSensors" = true ]; then
            # Only sets temperature to master temperature in the app
            queryAirCon "http://$IP:2025/setAircon?json={ac1:{info:{setTemp:$value}}}" "1" "0"
            exit 0
         else
            # Sets all zones to the current master thermostat's temperature value. All 10 allowable zones have been added just in case and do not need removing.
            queryAirCon "http://$IP:2025/setAircon?json={ac1:{info:{setTemp:$value},zones:{z01:{setTemp:$value},z02:{setTemp:$value},z03:{setTemp:$value},z04:{setTemp:$value},z05:{setTemp:$value},z06:{setTemp:$value},z07:{setTemp:$value},z08:{setTemp:$value},z09:{setTemp:$value},z10:{setTemp:$value}}}}" "1" "0"
            exit 0
         fi
      ;;

      On )
         # Uses the On characteristic for Fan/Vent mode.
         if [ $zoneSpecified = false ] && [ $fanSpeed = false ]; then
            if [ "$value" = "1" ]; then
               # Sets Control Unit to On, sets to Fan mode aqnd fan speed will default to last used.
               queryAirCon "http://$IP:2025/setAircon?json={ac1:{info:{state:on,mode:vent}}}" "1" "0"

               exit 0
            else
               # Shut Off Control Unit.
               queryAirCon "http://$IP:2025/setAircon?json={ac1:{info:{state:off}}}" "1" "0"

               exit 0
            fi
         # Uses the On characteristic for zone switches.
         elif [ $zoneSpecified = true ]; then
            if [ "$value" = "1" ]; then
               queryAirCon "http://$IP:2025/setAircon?json={ac1:{zones:{$zone:{state:open}}}}" "1" "0"

               exit 0
            else
               queryAirCon "http://$IP:2025/setAircon?json={ac1:{zones:{$zone:{state:close}}}}" "1" "0"

               exit 0
            fi
         fi
      ;;

      #Light Bulb service for used controlling damper % open
      Brightness )
         #round the $value to its nearst 5%
         damper=$(expr $(expr $(expr $value + 2) / 5) \* 5)

         queryAirCon "http://$IP:2025/setAircon?json={ac1:{zones:{$zone:{value:$damper}}}}" "1" "0"
         exit 0
      ;;

      # Fan service for controlling fan speed (0-33%:low, 34-67%:medium, 68-99%:high, 100%:autoAA/auto)
      RotationSpeed )
         # fspeed=$value (0-33%:low, 34-67%:medium, 68-99%:high, 100%:autoAA/auto)
         if [ $value -le 33 ]; then
            fspeed="low"
         elif [ $value -ge 34 ] && [ $value -le 67 ]; then
            fspeed="medium"
         elif [ $value -ge 68 ] && [ $value -le 99 ]; then
            fspeed="high"
         else
            # 'ezfan' users have 'autoAA' and regular users have 'auto'. But 'autoAA' works for all, so hardcoded to 'autoAA'
            fspeed="autoAA"
         fi
         queryAirCon "http://$IP:2025/setAircon?json={ac1:{info:{fan:$fspeed}}}" "1" "0"

         exit 0
      ;;

   esac
fi

echo "Unhandled $io $device $characteristic" >&2

exit 150
