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
   rm -f "/tmp/AA-001/AirConServer.out"
}

beforeEach()
{
   rm -f "/tmp/AA-001/myAirData.txt"*
   rm -f "/tmp/AA-001/myAirConstants.txt"*
   if [ ! -d "/tmp/AA-001" ]; then mkdir "/tmp/AA-001"; fi
}

@test "AdvAir Test Get RotationSpeed" {
   beforeEach
   # Issue the reInit
   curl -s -g "http://localhost:2025/reInit"
   # Do the load
   curl -s -g "http://localhost:2025?load=testData/basicPassingSystemData.txt"
   # Bats "run" gobbles up all the stdout. Remove for debugging
   run ../AdvAir.sh Get Blah RotationSpeed TEST_ON 127.0.0.1 fanSpeed
   assert_equal "$status" 0
   assert_equal "${lines[0]}" "Using IP: 127.0.0.1"
   assert_equal "${lines[1]}" "Try 0"
   assert_equal "${lines[2]}" "Parsing for jqPath: .aircons.ac1.info"
   assert_equal "${lines[3]}" "Parsing for jqPath: .aircons.ac1.info.noOfZones"
   assert_equal "${lines[4]}" "Parsing for jqPath: .aircons.ac1.zones.z01.rssi"
   assert_equal "${lines[5]}" "Parsing for jqPath: .aircons.ac1.info.constant1"
   assert_equal "${lines[6]}" "Parsing for jqPath: .aircons.ac1.info.fan"
   assert_equal "${lines[7]}" "100"
   # No more lines than expected
   assert_equal "${#lines[@]}" 8
}
