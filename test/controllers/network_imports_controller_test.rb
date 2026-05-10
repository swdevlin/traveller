require 'test_helper'

class NetworkImportsControllerTest < AuthenticatedIntegrationTest
  setup do
    @network = networks(:one)
    @sys_a   = star_systems(:in_one)
    @sys_b   = star_systems(:in_two)
  end

  test 'imports links from valid csv' do
    csv = "from_system,to_system\n#{@sys_a.name},#{@sys_b.name}\n"
    file = Rack::Test::UploadedFile.new(StringIO.new(csv), 'text/csv', original_filename: 'links.csv')

    # Remove the existing fixture link so we can import fresh
    NetworkLink.delete_all

    assert_difference('NetworkLink.count') do
      post network_network_import_url(@network), params: { file: file }
    end

    assert_redirected_to network_url(@network)
    assert_match(/Imported 1 link/, flash[:notice])
  end

  test 'skips rows where system name not found' do
    csv = "from_system,to_system\nUnknown System,Also Unknown\n"
    file = Rack::Test::UploadedFile.new(StringIO.new(csv), 'text/csv', original_filename: 'links.csv')

    assert_no_difference('NetworkLink.count') do
      post network_network_import_url(@network), params: { file: file }
    end

    assert_redirected_to network_url(@network)
    assert_match(/skipped/, flash[:notice])
  end

  test 'skips duplicate links' do
    # Create via AR so normalize_direction runs and the pair is correctly stored
    NetworkLink.delete_all
    NetworkLink.create!(network: @network, from_star_system: @sys_a, to_star_system: @sys_b)

    csv = "from_system,to_system\n#{@sys_a.name},#{@sys_b.name}\n"
    file = Rack::Test::UploadedFile.new(StringIO.new(csv), 'text/csv', original_filename: 'links.csv')

    assert_no_difference('NetworkLink.count') do
      post network_network_import_url(@network), params: { file: file }
    end

    assert_match(/skipped/, flash[:notice])
  end

  test 'redirects with alert when no file given' do
    post network_network_import_url(@network)
    assert_redirected_to network_url(@network)
    assert_match(/No file/, flash[:alert])
  end
end
