setup()
{
   load './test/setup'
   _common_setup
}

teardown()
{
   _common_teardown
}
before()
{
   if [ -f "/tmp/AirConServer.out" ]; then
      rm "/tmp/AirConServer.out"
   fi
}

beforeEach()
{
   if [ -f "/tmp/myAirData.txt" ]; then
      rm "/tmp/myAirData.txt"
   fi
   if [ -f "/tmp/myAirData.txt.date" ]; then
      rm "/tmp/myAirData.txt.date"
   fi
   if [ -f "/tmp/myAirData.txt.lock" ]; then
      rm "/tmp/myAirData.txt.lock"
   fi
   if [ -f "/tmp/myAirConstants.txt" ]; then
      rm "/tmp/myAirConstants.txt"
   fi
}

# Typical GarageDoorConfig for currentDoorState
#  "type": "GarageDoorOpener",
#  "displayName": "Garage Door",
#  "currentDoorState": 0,
#  "targetDoorState": 0,
#  "polling": [ { "characteristic": "currentDoorState" },
#               { "characteristic": "targetDoorState" }
#             ],
#  "state_cmd_suffix": "'thing:Garage' ${IP}"

@test "AdvAir ( PassOn1 ) Test Get TargetDoorState" {
   beforeEach
   # Issue the reInit
   curl -s -g "http://localhost:$PORT/reInit"
   # Do the load
   curl -s -g "http://localhost:$PORT?load=testData/myPlace.txt"
   run ../AdvAir.sh Get Blah TargetDoorState 'thing:Garage' 127.0.0.1 TEST_ON
   assert_equal "$status" 0
   assert_equal "${lines[0]}" "Try 0"
   assert_equal "${lines[1]}" "Parsing for jqPath: .aircons.ac1.info"
   assert_equal "${lines[2]}" "Parsing for jqPath: .aircons.ac1.info.noOfZones"
   assert_equal "${lines[3]}" "Parsing for jqPath: .aircons.ac1.zones.z01.rssi"
   assert_equal "${lines[4]}" "Parsing for jqPath: .aircons.ac1.info.constant1"
   assert_equal "${lines[5]}" "path: thing name: Garage ids=\"6801801\""
   assert_equal "${lines[6]}" "Parsing for jqPath: .myThings.things.\"6801801\".value"
   assert_equal "${lines[7]}" "1"
   # No more lines than expected
   assert_equal "${#lines[@]}" 8
}

@test "AdvAir ( PassOn1 ) Test Get TargetDoorState - flip enabled" {
   beforeEach
   # Issue the reInit
   curl -s -g "http://localhost:$PORT/reInit"
   # Do the load
   curl -s -g "http://localhost:$PORT?load=testData/myPlace.txt"
   run ../AdvAir.sh Get Blah TargetDoorState 'thing:Garage' flip 127.0.0.1 TEST_ON
   assert_equal "$status" 0
   assert_equal "${lines[0]}" "Try 0"
   assert_equal "${lines[1]}" "Parsing for jqPath: .aircons.ac1.info"
   assert_equal "${lines[2]}" "Parsing for jqPath: .aircons.ac1.info.noOfZones"
   assert_equal "${lines[3]}" "Parsing for jqPath: .aircons.ac1.zones.z01.rssi"
   assert_equal "${lines[4]}" "Parsing for jqPath: .aircons.ac1.info.constant1"
   assert_equal "${lines[5]}" "path: thing name: Garage ids=\"6801801\""
   assert_equal "${lines[6]}" "Parsing for jqPath: .myThings.things.\"6801801\".value"
   # flip should make this a 0
   assert_equal "${lines[7]}" "0"
   # No more lines than expected
   assert_equal "${#lines[@]}" 8
}
