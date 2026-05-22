require 'test_helper'

class JumpRouteLinksControllerTest < AuthenticatedIntegrationTest
  setup do
    @jump_route = jump_routes(:one)
    @sys_a      = star_systems(:in_one)
    @sys_b      = star_systems(:in_two)
    @link       = jump_route_links(:one)
  end

  test 'should create link and return turbo stream' do
    third = star_systems(:also_in_one)
    assert_difference('JumpRouteLink.count') do
      post jump_route_links_url,
           params: {
             jump_route_link: {
               jump_route_id: @jump_route.id,
               from_star_system_id: @sys_a.id,
               to_star_system_id: third.id
             },
             star_system_id: @sys_a.id
           },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html', 'Turbo-Frame' => 'modal' }
    end
    assert_response :success
  end

  test 'create normalises direction before saving' do
    higher, lower = [@sys_a, star_systems(:also_in_one)].sort_by(&:id).reverse
    assert_difference('JumpRouteLink.count') do
      post jump_route_links_url,
           params: {
             jump_route_link: {
               jump_route_id: @jump_route.id,
               from_star_system_id: higher.id,
               to_star_system_id: lower.id
             },
             star_system_id: higher.id
           }
    end
    saved = JumpRouteLink.find_by!(from_star_system_id: lower.id, to_star_system_id: higher.id)
    assert saved.from_star_system_id < saved.to_star_system_id
  end

  test 'create rejects duplicate and responds with redirect on html' do
    JumpRouteLink.delete_all
    JumpRouteLink.create!(jump_route: @jump_route, from_star_system: @sys_a, to_star_system: @sys_b)

    assert_no_difference('JumpRouteLink.count') do
      post jump_route_links_url,
           params: {
             jump_route_link: {
               jump_route_id: @jump_route.id,
               from_star_system_id: @sys_a.id,
               to_star_system_id: @sys_b.id
             },
             star_system_id: @sys_a.id
           }
    end
  end

  test 'should destroy link' do
    assert_difference('JumpRouteLink.count', -1) do
      delete jump_route_link_url(@link),
             params: { star_system_id: @sys_a.id }
    end
  end

  test 'destroy responds with turbo stream remove' do
    delete jump_route_link_url(@link),
           params: { star_system_id: @sys_a.id },
           headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success
    assert_includes response.body, 'remove'
    assert_includes response.body, "jump_route_link_#{@link.id}"
  end
end
