require "test_helper"

class TechLevelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tech_level = tech_levels(:one)
  end

  test "should get index" do
    get tech_levels_url
    assert_response :success
  end

  test "should get new" do
    get new_tech_level_url
    assert_response :success
  end

  test "should create tech_level" do
    assert_difference("TechLevel.count") do
      post tech_levels_url, params: { tech_level: { air: @tech_level.air, code: 3, electronics: @tech_level.electronics, energy: @tech_level.energy, environmental: @tech_level.environmental, heavy_military: @tech_level.heavy_military, land: @tech_level.land, manufacturing: @tech_level.manufacturing, medical: @tech_level.medical, notes: @tech_level.notes, personal_military: @tech_level.personal_military, sea: @tech_level.sea, space: @tech_level.space } }
    end

    assert_redirected_to tech_level_url(TechLevel.last)
  end

  test "should show tech_level" do
    get tech_level_url(@tech_level)
    assert_response :success
  end

  test "should get edit" do
    get edit_tech_level_url(@tech_level)
    assert_response :success
  end

  test "should update tech_level" do
    patch tech_level_url(@tech_level), params: { tech_level: { air: @tech_level.air, code: @tech_level.code, electronics: @tech_level.electronics, energy: @tech_level.energy, environmental: @tech_level.environmental, heavy_military: @tech_level.heavy_military, land: @tech_level.land, manufacturing: @tech_level.manufacturing, medical: @tech_level.medical, notes: @tech_level.notes, personal_military: @tech_level.personal_military, sea: @tech_level.sea, space: @tech_level.space } }
    assert_redirected_to tech_level_url(@tech_level)
  end

  test "should destroy tech_level" do
    assert_difference("TechLevel.count", -1) do
      delete tech_level_url(@tech_level)
    end

    assert_redirected_to tech_levels_url
  end
end
