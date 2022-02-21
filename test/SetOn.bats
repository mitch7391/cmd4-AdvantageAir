setup()
{
   load './test/setup'
   _common_setup
}

teardown()
{
   _common_teardown
}


@test "AdvAir ( ezone inline ) Test PassOn5 Set On 1" {
   # We symbolically link the directory of the test we want to use.
   ln -s ./testData/dataPassOn5 ./data
   # Bats "run" gobbles up all the stdout. Remove for debugging
   run ./compare/ezone.txt Set Fan On 1 TEST_ON
   assert_equal "$status" 0
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{info:{state:on,mode:vent,fan:auto}}}"
   e_status=$status
   e_lines=("${lines[@]}")
   run ./compare/AdvAir.sh Set Fan On 1 192.168.0.173 TEST_ON
   # No longer the same
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{info:{state:on,mode:vent}}}"
   assert_equal "$status" "$e_status"

}

# ezone (Cannot use compare as old does not allow IP and IP is now mandatory
@test "AdvAir ( ezone inline ) Test PassOn3 Set On 1" {
   ln -s ./testData/dataPassOn3 ./data
   run ./compare/ezone.txt Set Fan On 1 TEST_ON
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{info:{state:on,mode:vent,fan:auto}}}"
   e_status=$status
   e_lines=("${lines[@]}")
   run ./compare/AdvAir.sh Set Fan On 1 192.168.0.173 TEST_ON
   # No longer the same
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{info:{state:on,mode:vent}}}"
   assert_equal "$status" "$e_status"
}

@test "AdvAir ( ezone inline ) Test FailOn5 Set On 1" {
   ln -s ./testData/dataFailOn5 ./data
   run ./compare/ezone.txt Set Fan On 1 TEST_ON
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{info:{state:on,mode:vent,fan:auto}}}"
   e_status=$status
   e_lines=("${lines[@]}")
   run ./compare/AdvAir.sh Set Fan On 1 192.168.0.173 TEST_ON
   # No longer the same
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{info:{state:on,mode:vent}}}"
   assert_equal "$status" "$e_status"

}


# zones (Cannot use compare as old does not allow IP and IP is now mandatory
@test "AdvAir ( zones inline ) Test PassOn1 Set On 1 z01" {
   # We symbolically link the directory of the test we want to use.
   ln -s ./testData/dataPassOn1 ./data
   run ./compare/zones.txt Set Fan On 1 z01 TEST_ON
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{zones:{z01:{state:open}}}}"
   e_status=$status
   e_lines=("${lines[@]}")
   run ./compare/AdvAir.sh Set Fan On 1 z01 192.168.0.173 TEST_ON
   assert_equal "${lines[0]}" "${e_lines[0]}"
   assert_equal "$status" "$e_status"
}

@test "AdvAir ( zones inline ) Test PassOn3 Set On 1 z01" {
   ln -s ./testData/dataPassOn3 ./data
   run ./compare/zones.txt Set Fan On 1 z01 TEST_ON
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{zones:{z01:{state:open}}}}"
   e_status=$status
   e_lines=("${lines[@]}")
   run ./compare/AdvAir.sh Set Fan On 1 z01 192.168.0.173 TEST_ON
   assert_equal "${lines[0]}" "${e_lines[0]}"
   assert_equal "$status" "$e_status"
}

@test "AdvAir ( zones inline ) Test PassOn5 Set On 1 z01" {
   ln -s ./testData/dataPassOn5 ./data
   run ./compare/zones.txt Set Fan On 1 z01 TEST_ON
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{zones:{z01:{state:open}}}}"
   e_status=$status
   e_lines=("${lines[@]}")
   run ./compare/AdvAir.sh Set Fan On 1 z01 192.168.0.173 TEST_ON
   assert_equal "${lines[0]}" "${e_lines[0]}"
   assert_equal "$status" "$e_status"
}

@test "AdvAir ( zones inline ) Test FailOn5 Set On 1 z01" {
   ln -s ./testData/dataFailOn5 ./data
   run ./compare/zones.txt Set Fan On 1 z01 TEST_ON
   assert_equal "${lines[0]}" "Setting url: http://192.168.0.173:2025/setAircon?json={ac1:{zones:{z01:{state:open}}}}"
   e_status=$status
   e_lines=("${lines[@]}")
   run ./compare/AdvAir.sh Set Fan On 1 z01 192.168.0.173 TEST_ON
   assert_equal "${lines[0]}" "${e_lines[0]}"
   assert_equal "$status" "$e_status"
}
