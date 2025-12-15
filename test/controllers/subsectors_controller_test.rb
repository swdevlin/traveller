require "test_helper"

class SubsectorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subsector = subsectors(:one)
  end

  test "should get index" do
    get subsectors_url
    assert_response :success
  end

  test "should get new" do
    get new_subsector_url
    assert_response :success
  end

  test "should create subsector" do
    assert_difference("Subsector.count") do
      post subsectors_url, params: { subsector: { name: @subsector.name, x: @subsector.x, y: @subsector.y } }
    end

    assert_redirected_to subsector_url(Subsector.last)
  end

  test "should show subsector" do
    get subsector_url(@subsector)
    assert_response :success
  end

  test "should get edit" do
    get edit_subsector_url(@subsector)
    assert_response :success
  end

  test "should update subsector" do
    patch subsector_url(@subsector), params: { subsector: { name: @subsector.name, x: @subsector.x, y: @subsector.y } }
    assert_redirected_to subsector_url(@subsector)
  end

  test "should destroy subsector" do
    assert_difference("Subsector.count", -1) do
      delete subsector_url(@subsector)
    end

    assert_redirected_to subsectors_url
  end
end
