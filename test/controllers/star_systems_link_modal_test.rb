require 'test_helper'

class StarSystemsLinkModalTest < AuthenticatedIntegrationTest
  setup do
    @star_system = star_systems(:in_one)
    @network     = communication_networks(:one)
  end

  test 'link_modal renders without network selected' do
    # No networks exist other than fixture — just verify it renders
    get link_modal_star_system_url(@star_system)
    assert_response :success
  end

  test 'link_modal renders with a network selected' do
    get link_modal_star_system_url(@star_system), params: { network_id: @network.id }
    assert_response :success
  end
end
