require "test_helper"

class SubsectorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @subsector = subsectors(:one)
    @sector = sectors(:one)
  end

  test "should get index" do
    get subsectors_url
    assert_response :success
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

end
