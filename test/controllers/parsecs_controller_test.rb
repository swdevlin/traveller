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
    patch parsec_url(@parsec), params: { parsec: { note: 'New note' } }
    assert_redirected_to parsec_url(@parsec)
  end

  test 'x cannot be changed via update' do
    original_x = @parsec.x
    patch parsec_url(@parsec), params: { parsec: { x: original_x + 5, note: 'sneaky' } }
    assert_equal original_x, @parsec.reload.x
  end

  test 'y cannot be changed via update' do
    original_y = @parsec.y
    patch parsec_url(@parsec), params: { parsec: { y: original_y + 5, note: 'sneaky' } }
    assert_equal original_y, @parsec.reload.y
  end

  test 'sector cannot be changed via update' do
    original_sector_id = @parsec.sector_id
    other_sector = sectors(:two)
    patch parsec_url(@parsec), params: { parsec: { sector_id: other_sector.id, note: 'sneaky' } }
    assert_equal original_sector_id, @parsec.reload.sector_id
  end
end
