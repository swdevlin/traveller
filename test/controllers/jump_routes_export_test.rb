require 'test_helper'

class JumpRoutesExportTest < AuthenticatedIntegrationTest
  setup do
    @jump_route = jump_routes(:one)
  end

  test 'export_links returns csv with headers' do
    get export_links_jump_route_url(@jump_route)
    assert_response :success
    assert_equal 'text/csv', response.media_type
    assert_includes response.body, 'from_system'
    assert_includes response.body, 'to_system'
  end

  test 'export_links includes link data' do
    link = jump_route_links(:one)
    get export_links_jump_route_url(@jump_route)
    assert_includes response.body, link.from_star_system.name
    assert_includes response.body, link.to_star_system.name
  end
end
