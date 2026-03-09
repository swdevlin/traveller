require "test_helper"

class ShipsControllerTest < AuthenticatedIntegrationTest
  setup do
    @ship = ships(:one)
  end

  test "should get index" do
    get ships_url
    assert_response :success
  end

  test "should get new" do
    get new_ship_url
    assert_response :success
  end

  test "should create ship" do
    assert_difference("Ship.count") do
      post ships_url, params: { ship: { jump_drive: @ship.jump_drive, name: @ship.name } }
    end

    assert_redirected_to ship_url(Ship.last)
  end

  test "should show ship" do
    get ship_url(@ship)
    assert_response :success
  end

  test "should get edit" do
    get edit_ship_url(@ship)
    assert_response :success
  end

  test "should update ship" do
    patch ship_url(@ship), params: { ship: { jump_drive: @ship.jump_drive, name: @ship.name } }
    assert_redirected_to ship_url(@ship)
  end

  test "should destroy ship" do
    assert_difference("Ship.count", -1) do
      delete ship_url(@ship)
    end

    assert_redirected_to ships_url
  end
end
