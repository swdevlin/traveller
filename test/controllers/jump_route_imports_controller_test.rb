require 'test_helper'

class JumpRouteImportsControllerTest < AuthenticatedIntegrationTest
  setup do
    @jump_route = jump_routes(:one)
    @sys_a      = star_systems(:in_one)
    @sys_b      = star_systems(:in_two)
  end

  test 'imports links from valid csv' do
    csv = "from_system,to_system\n#{@sys_a.name},#{@sys_b.name}\n"
    file = Rack::Test::UploadedFile.new(StringIO.new(csv), 'text/csv', original_filename: 'links.csv')

    JumpRouteLink.delete_all

    assert_difference('JumpRouteLink.count') do
      post jump_route_jump_route_import_url(@jump_route), params: { file: file }
    end

    assert_redirected_to jump_route_url(@jump_route)
    assert_match(/Imported 1 link/, flash[:notice])
  end

  test 'skips rows where system name not found' do
    csv = "from_system,to_system\nUnknown System,Also Unknown\n"
    file = Rack::Test::UploadedFile.new(StringIO.new(csv), 'text/csv', original_filename: 'links.csv')

    assert_no_difference('JumpRouteLink.count') do
      post jump_route_jump_route_import_url(@jump_route), params: { file: file }
    end

    assert_redirected_to jump_route_url(@jump_route)
    assert_match(/skipped/, flash[:notice])
  end

  test 'skips duplicate links' do
    JumpRouteLink.delete_all
    JumpRouteLink.create!(jump_route: @jump_route, from_star_system: @sys_a, to_star_system: @sys_b)

    csv = "from_system,to_system\n#{@sys_a.name},#{@sys_b.name}\n"
    file = Rack::Test::UploadedFile.new(StringIO.new(csv), 'text/csv', original_filename: 'links.csv')

    assert_no_difference('JumpRouteLink.count') do
      post jump_route_jump_route_import_url(@jump_route), params: { file: file }
    end

    assert_match(/skipped/, flash[:notice])
  end

  test 'redirects with alert when no file given' do
    post jump_route_jump_route_import_url(@jump_route)
    assert_redirected_to jump_route_url(@jump_route)
    assert_match(/No file/, flash[:alert])
  end
end
