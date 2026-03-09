require "test_helper"

class JumpLogsControllerTest < AuthenticatedIntegrationTest
  setup do
    @jump_log = jump_logs(:one)
  end

  test "should get index" do
    get jump_logs_url
    assert_response :success
  end

  test "should get new" do
    get new_jump_log_url
    assert_response :success
  end

  test "should create jump_log" do
    assert_difference("JumpLog.count") do
      post jump_logs_url, params: { jump_log: { arrive_day: @jump_log.arrive_day, arrive_year: @jump_log.arrive_year, depart_day: @jump_log.depart_day, depart_year: @jump_log.depart_year, from_parsec_id: @jump_log.from_parsec_id, notes: @jump_log.notes, ship_id: @jump_log.ship_id, to_parsec_id: @jump_log.to_parsec_id, misjump: false } }
    end

    assert_redirected_to jump_logs_url
  end

  test "should create misjump" do
    assert_difference("JumpLog.count") do
      post jump_logs_url, params: { jump_log: { arrive_day: @jump_log.arrive_day, arrive_year: @jump_log.arrive_year, depart_day: @jump_log.depart_day, depart_year: @jump_log.depart_year, from_parsec_id: @jump_log.from_parsec_id, notes: @jump_log.notes, ship_id: @jump_log.ship_id, to_parsec_id: @jump_log.to_parsec_id, misjump: true } }
    end

    assert JumpLog.last.misjump?
    assert_redirected_to jump_logs_url
  end

  test "should show jump_log" do
    get jump_log_url(@jump_log)
    assert_response :success
  end

  test "should get edit" do
    get edit_jump_log_url(@jump_log)
    assert_response :success
  end

  test "should update jump_log" do
    patch jump_log_url(@jump_log), params: { jump_log: { arrive_day: @jump_log.arrive_day, arrive_year: @jump_log.arrive_year, depart_day: @jump_log.depart_day, depart_year: @jump_log.depart_year, from_parsec_id: @jump_log.from_parsec_id, notes: @jump_log.notes, ship_id: @jump_log.ship_id, to_parsec_id: @jump_log.to_parsec_id, misjump: true } }
    assert @jump_log.reload.misjump?
    assert_redirected_to jump_log_url(@jump_log)
  end

  test "should destroy jump_log" do
    assert_difference("JumpLog.count", -1) do
      delete jump_log_url(@jump_log)
    end

    assert_redirected_to jump_logs_url
  end
end
