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

@test "AdvAir ( ezone inline ) Test PassOn5 Get CurrentHeatingCoolingState" {
   beforeEach
   # Issue the reInit
   curl -s -g "http://localhost:$PORT/reInit"
   # Do the load
   curl -s -g "http://localhost:$PORT?repeat=4&load=testData/dataPassOn5/getSystemData.txt0"
   curl -s -g "http://localhost:$PORT?load=testData/dataPassOn5/getSystemData.txt4"
   # Bats "run" gobbles up all the stdout. Remove for debugging
   run ../AdvAir.sh Get Blah CurrentHeatingCoolingState 127.0.0.1 TEST_ON
   assert_equal "$status" 0
   assert_equal "${lines[0]}" "Try 0"
   assert_equal "${lines[1]}" "Try 1"
   assert_equal "${lines[2]}" "Try 2"
   assert_equal "${lines[3]}" "Try 3"
   assert_equal "${lines[4]}" "Try 4"
   assert_equal "${lines[5]}" "2"
   # No more lines than expected
   assert_equal "${#lines[@]}" 6
}

@test "AdvAir ( ezone inline ) Test PassOn1 Get CurrentHeatingCoolingState" {
   beforeEach
   # Issue the reInit
   curl -s -g "http://localhost:$PORT/reInit"
   # Do the load
   curl -s -g "http://localhost:$PORT?load=testData/dataPassOn1/getSystemData.txt0"
   # Bats "run" gobbles up all the stdout. Remove for debugging
   run ../AdvAir.sh Get Blah CurrentHeatingCoolingState 127.0.0.1 TEST_ON
   assert_equal "$status" 0
   assert_equal "${lines[0]}" "Try 0"
   assert_equal "${lines[1]}" "2"
   # No more lines than expected
   assert_equal "${#lines[@]}" 2
}

@test "AdvAir ( ezone inline ) Test PassOn3 Get CurrentHeatingCoolingState" {
   beforeEach
   # Issue the reInit
   curl -s -g "http://localhost:$PORT/reInit"
   # Do the load
   curl -s -g "http://localhost:$PORT?repeat=2&load=testData/dataPassOn3/getSystemData.txt0"
   curl -s -g "http://localhost:$PORT?load=testData/dataPassOn3/getSystemData.txt2"
   # Bats "run" gobbles up all the stdout. Remove for debugging
   run ../AdvAir.sh Get Blah CurrentHeatingCoolingState 127.0.0.1 TEST_ON
   assert_equal "$status" 0
   assert_equal "${lines[0]}" "Try 0"
   assert_equal "${lines[1]}" "Try 1"
   assert_equal "${lines[2]}" "Try 2"
   assert_equal "${lines[3]}" "2"
   # No more lines than expected
   assert_equal "${#lines[@]}" 4
}

@test "AdvAir ( ezone inline ) Test FailOn5 Get CurrentHeatingCoolingState" {
   beforeEach
   # Issue the reInit
   curl -s -g "http://localhost:$PORT/reInit"
   # Do the load
   curl -s -g "http://localhost:$PORT?load=testData/dataFailOn5/getSystemData.txt0"
   # Bats "run" gobbles up all the stdout. Remove for debugging
   run ../AdvAir.sh Get Blah CurrentHeatingCoolingState 127.0.0.1 TEST_ON
   assert_equal "$status" 1
   assert_equal "${lines[0]}" "Try 0"
   assert_equal "${lines[1]}" "Try 1"
   assert_equal "${lines[2]}" "Try 2"
   assert_equal "${lines[3]}" "Try 3"
   assert_equal "${lines[4]}" "Try 4"
   # No more lines than expected
   assert_equal "${#lines[@]}" 5
}
