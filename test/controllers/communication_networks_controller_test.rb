require 'test_helper'

class CommunicationNetworksControllerTest < AuthenticatedIntegrationTest
  setup do
    @communication_network = communication_networks(:one)
  end

  test 'should get index' do
    get communication_networks_url
    assert_response :success
  end

  test 'should get new' do
    get new_communication_network_url
    assert_response :success
  end

  test 'should create communication_network' do
    assert_difference('CommunicationNetwork.count') do
      post communication_networks_url, params: { communication_network: { name: 'X-boat Network', colour: '#ff0000', max_jump: 2, known: true, notes: '' } }
    end

    assert_redirected_to communication_network_url(CommunicationNetwork.last)
  end

  test 'should show communication_network' do
    get communication_network_url(@communication_network)
    assert_response :success
  end

  test 'should get edit' do
    get edit_communication_network_url(@communication_network)
    assert_response :success
  end

  test 'should update communication_network' do
    patch communication_network_url(@communication_network), params: { communication_network: { name: @communication_network.name } }
    assert_redirected_to communication_network_url(@communication_network)
  end

  test 'should destroy communication_network' do
    assert_difference('CommunicationNetwork.count', -1) do
      delete communication_network_url(@communication_network)
    end

    assert_redirected_to communication_networks_url
  end
end
