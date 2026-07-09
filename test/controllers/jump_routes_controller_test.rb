require 'test_helper'

class JumpRoutesControllerTest < AuthenticatedIntegrationTest
  setup do
    @jump_route = jump_routes(:one)
  end

  test 'should get index' do
    get jump_routes_url
    assert_response :success
  end

  test 'should get new' do
    get new_jump_route_url
    assert_response :success
  end

  test 'should create jump route' do
    assert_difference('JumpRoute.count') do
      post jump_routes_url, params: { jump_route: { name: 'X-boat Route', colour: '#ff0000', max_jump: 2, known: true, notes: '', line_style: 'solid', line_width: 4 } }
    end

    assert_redirected_to jump_route_url(JumpRoute.last)
  end

  test 'should show jump route' do
    get jump_route_url(@jump_route)
    assert_response :success
  end

  test 'should get edit' do
    get edit_jump_route_url(@jump_route)
    assert_response :success
  end

  test 'should update jump route' do
    patch jump_route_url(@jump_route), params: { jump_route: { name: @jump_route.name } }
    assert_redirected_to jump_route_url(@jump_route)
  end

  test 'should destroy jump route' do
    assert_difference('JumpRoute.count', -1) do
      delete jump_route_url(@jump_route)
    end

    assert_redirected_to jump_routes_url
  end
end
