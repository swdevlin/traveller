require 'test_helper'

class StarSystemsLinkModalTest < AuthenticatedIntegrationTest
  setup do
    @star_system = star_systems(:in_one)
    @jump_route  = jump_routes(:one)
  end

  test 'link_modal renders without jump route selected' do
    # No jump routes exist other than fixture — just verify it renders
    get link_modal_star_system_url(@star_system)
    assert_response :success
  end

  test 'link_modal renders with a jump route selected' do
    get link_modal_star_system_url(@star_system), params: { jump_route_id: @jump_route.id }
    assert_response :success
  end
end
