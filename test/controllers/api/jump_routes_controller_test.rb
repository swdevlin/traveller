# frozen_string_literal: true

require 'test_helper'

class Api::JumpRoutesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  test 'index returns known network and plotted routes without authentication, omitting notes' do
    network = JumpRoute.create!(name: 'Network Route', colour: '#112233', known: true, notes: 'Secret referee notes')
    plotted = JumpRoute.create!(name: 'Plotted Route', route_type: 'plotted', known: true, notes: 'Other notes')
    JumpRouteLink.create!(jump_route: network, from_star_system: star_systems(:in_one), to_star_system: star_systems(:in_two))

    get api_jump_routes_url(campaign_slug: @campaign.slug), as: :json

    assert_response :success
    body = response.parsed_body
    ids = body.map { |r| r['id'] }
    assert_includes ids, network.id
    assert_includes ids, plotted.id

    entry = body.find { |r| r['id'] == network.id }
    assert_equal 'Network Route', entry['name']
    assert_equal '#112233', entry['colour']
    assert_equal 'network', entry['route_type']
    assert_equal 1, entry['link_count']
    assert_nil entry['notes']
  end

  test 'index omits unknown routes without authentication' do
    unknown = JumpRoute.create!(name: 'Referee Secret Route', known: false)

    get api_jump_routes_url(campaign_slug: @campaign.slug), as: :json

    assert_response :success
    ids = response.parsed_body.map { |r| r['id'] }
    assert_not_includes ids, unknown.id
  end

  test 'index includes unknown routes and notes for an authenticated session' do
    route = JumpRoute.create!(name: 'Network Route', known: false, notes: 'Secret referee notes')
    sign_in_as users(:one)

    get api_jump_routes_url(campaign_slug: @campaign.slug), as: :json

    assert_response :success
    entry = response.parsed_body.find { |r| r['id'] == route.id }
    assert entry
    assert_equal 'Secret referee notes', entry['notes']
  end

  test 'index includes unknown routes for a valid bearer token' do
    route = JumpRoute.create!(name: 'Network Route', known: false)

    get api_jump_routes_url(campaign_slug: @campaign.slug),
        headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json

    assert_response :success
    ids = response.parsed_body.map { |r| r['id'] }
    assert_includes ids, route.id
  end

  test 'update without credentials returns unauthorised' do
    route = JumpRoute.create!(name: 'Network Route')

    patch api_jump_route_url(campaign_slug: @campaign.slug, id: route.id),
          params: { name: 'Renamed' }, as: :json

    assert_response :unauthorized
    assert_equal 'Network Route', route.reload.name
  end

  test 'update with active session changes permitted fields on a network route' do
    sign_in_as users(:one)
    route = JumpRoute.create!(name: 'Network Route', colour: '#000000')

    patch api_jump_route_url(campaign_slug: @campaign.slug, id: route.id),
          params: { name: 'Renamed', colour: '#ffffff', known: true }, as: :json

    assert_response :success
    route.reload
    assert_equal 'Renamed', route.name
    assert_equal '#ffffff', route.colour
    assert route.known?
  end

  test 'update on a plotted route is rejected and leaves it unchanged' do
    sign_in_as users(:one)
    route = JumpRoute.create!(name: 'Plotted Route', route_type: 'plotted', colour: '#123123')

    patch api_jump_route_url(campaign_slug: @campaign.slug, id: route.id),
          params: { name: 'Renamed', colour: '#ffffff' }, as: :json

    assert_response :unprocessable_entity
    route.reload
    assert_equal 'Plotted Route', route.name
    assert_equal '#123123', route.colour
  end

  test 'destroy without credentials returns unauthorised and destroys nothing' do
    route = JumpRoute.create!(name: 'Network Route')

    assert_no_difference -> { JumpRoute.count } do
      delete api_jump_route_url(campaign_slug: @campaign.slug, id: route.id), as: :json
    end
    assert_response :unauthorized
  end

  test 'destroy with active session cascades to jump_route_links' do
    sign_in_as users(:one)
    route = JumpRoute.create!(name: 'Network Route')
    JumpRouteLink.create!(jump_route: route, from_star_system: star_systems(:in_one), to_star_system: star_systems(:in_two))

    assert_difference -> { JumpRoute.count } => -1, -> { JumpRouteLink.count } => -1 do
      delete api_jump_route_url(campaign_slug: @campaign.slug, id: route.id), as: :json
    end
    assert_response :no_content
  end

  test 'destroy with valid bearer token succeeds' do
    route = JumpRoute.create!(name: 'Network Route')

    assert_difference -> { JumpRoute.count }, -1 do
      delete api_jump_route_url(campaign_slug: @campaign.slug, id: route.id),
             headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json
    end
    assert_response :no_content
  end
end
