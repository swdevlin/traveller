require "test_helper"

class ParsecsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @parsec = parsecs(:one)
    @sector = sectors(:one)
  end

  test "should get index" do
    get parsecs_url
    assert_response :success
  end

  test "should get new" do
    get new_parsec_url
    assert_response :success
  end

  test "should create parsec" do
    assert_difference("Parsec.count") do
      post parsecs_url, params: { parsec: { sector_id: @sector.id, x: 31, y: 31 } }
    end

    assert_redirected_to parsec_url(Parsec.last)
  end

  test "should show parsec" do
    get parsec_url(@parsec)
    assert_response :success
  end

  test "should get edit" do
    get edit_parsec_url(@parsec)
    assert_response :success
  end

  test "should update parsec" do
    patch parsec_url(@parsec), params: { parsec: { sector_id: @parsec.sector_id, x: @parsec.x, y: @parsec.y } }
    assert_redirected_to parsec_url(@parsec)
  end

  test "should destroy parsec" do
    assert_difference("Parsec.count", -1) do
      delete parsec_url(@parsec)
    end

    assert_redirected_to parsecs_url
  end
end
