require 'test_helper'

class CommunicationNetworksExportTest < AuthenticatedIntegrationTest
  setup do
    @network = communication_networks(:one)
  end

  test 'export_links returns csv with headers' do
    get export_links_communication_network_url(@network)
    assert_response :success
    assert_equal 'text/csv', response.media_type
    assert_includes response.body, 'from_system'
    assert_includes response.body, 'to_system'
  end

  test 'export_links includes link data' do
    link = network_links(:one)
    get export_links_communication_network_url(@network)
    assert_includes response.body, link.from_star_system.name
    assert_includes response.body, link.to_star_system.name
  end
end
