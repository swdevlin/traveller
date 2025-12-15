require "test_helper"

class SolarSystemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @solar_system = solar_systems(:one)
  end

  test "should get index" do
    get solar_systems_url
    assert_response :success
  end

  test "should get new" do
    get new_solar_system_url
    assert_response :success
  end

  test "should create solar_system" do
    assert_difference("SolarSystem.count") do
      post solar_systems_url, params: { solar_system: { meta: @solar_system.meta, name: @solar_system.name, origin_x: @solar_system.origin_x, origin_y: @solar_system.origin_y, sector_id: @solar_system.sector_id, x: @solar_system.x, y: @solar_system.y } }
    end

    assert_redirected_to solar_system_url(SolarSystem.last)
  end

  test "should show solar_system" do
    get solar_system_url(@solar_system)
    assert_response :success
  end

  test "should get edit" do
    get edit_solar_system_url(@solar_system)
    assert_response :success
  end

  test "should update solar_system" do
    patch solar_system_url(@solar_system), params: { solar_system: { meta: @solar_system.meta, name: @solar_system.name, origin_x: @solar_system.origin_x, origin_y: @solar_system.origin_y, sector_id: @solar_system.sector_id, x: @solar_system.x, y: @solar_system.y } }
    assert_redirected_to solar_system_url(@solar_system)
  end

  test "should destroy solar_system" do
    assert_difference("SolarSystem.count", -1) do
      delete solar_system_url(@solar_system)
    end

    assert_redirected_to solar_systems_url
  end
end
