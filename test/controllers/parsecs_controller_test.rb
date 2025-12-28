require 'test_helper'

class ParsecsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sector = sectors(:one)
    @parsec = parsecs(:two)
  end

  test 'should get index' do
    get parsecs_url
    assert_response :success
  end

  test 'should show parsec' do
    get parsec_url(@parsec)
    assert_response :success
  end

  test 'should get edit' do
    get edit_parsec_url(@parsec)
    assert_response :success
  end

  test 'should update parsec' do
    patch parsec_url(@parsec), params: { parsec: { sector_id: @parsec.sector_id, x: @parsec.x, y: @parsec.y } }
    assert_redirected_to parsec_url(@parsec)
  end
end
