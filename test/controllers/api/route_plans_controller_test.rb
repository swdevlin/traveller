# frozen_string_literal: true

require 'test_helper'

class Api::RoutePlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @sector = Sector.create!(name: 'Route Plan Controller Test Sector', x: 96, y: 96, abbreviation: 'Rpc')
  end

  def build_star_system(x, y, **attrs)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    StarSystem.create!({ name: "System #{x},#{y}", parsec: parsec }.merge(attrs))
  end

  test 'plan succeeds without authentication for an any-refueling route' do
    from = build_star_system(0, 0)
    to = build_star_system(1, 0)

    get api_route_plan_url(campaign_slug: @campaign.slug,
                            from_id: from.id, to_id: to.id, jump_range: 1, refueling: 'any'), as: :json

    assert_response :success
    body = response.parsed_body
    assert body['found']
    assert_equal 2, body['hops'].size
  end

  test 'plan in player mode reports no route when a referee would find one through an unsurveyed system' do
    from = build_star_system(10, 0)
    build_star_system(11, 0, gas_giant_count: 1, known: false, survey_index: 0)
    to = build_star_system(12, 0)

    get api_route_plan_url(campaign_slug: @campaign.slug,
                            from_id: from.id, to_id: to.id, jump_range: 1, refueling: 'wilderness'), as: :json
    assert_response :success
    assert_equal false, response.parsed_body['found']

    sign_in_as users(:one)
    get api_route_plan_url(campaign_slug: @campaign.slug,
                            from_id: from.id, to_id: to.id, jump_range: 1, refueling: 'wilderness'), as: :json
    assert_response :success
    assert_equal true, response.parsed_body['found']
  end

  test 'plan returns unprocessable_entity when from and to are the same system' do
    system = build_star_system(20, 0)

    get api_route_plan_url(campaign_slug: @campaign.slug,
                            from_id: system.id, to_id: system.id, jump_range: 1, refueling: 'any'), as: :json

    assert_response :unprocessable_entity
  end

  test 'save without credentials returns unauthorised and creates nothing' do
    from = build_star_system(30, 0)
    to = build_star_system(31, 0)

    assert_no_difference -> { JumpRoute.count } do
      post api_route_plan_save_url(campaign_slug: @campaign.slug),
           params: { name: 'My Route', colour: '#123456', jump_range: 1, refueling: 'any',
                     from_id: from.id, to_id: to.id, system_ids: [from.id, to.id] },
           as: :json
    end
    assert_response :unauthorized
  end

  test 'save with active session creates a plotted JumpRoute with links' do
    sign_in_as users(:one)
    from = build_star_system(40, 0)
    mid  = build_star_system(41, 0)
    to   = build_star_system(42, 0)

    assert_difference -> { JumpRoute.count } => 1, -> { JumpRouteLink.count } => 2 do
      post api_route_plan_save_url(campaign_slug: @campaign.slug),
           params: { name: 'My Route', colour: '#123456', jump_range: 1, refueling: 'any',
                     from_id: from.id, to_id: to.id, system_ids: [from.id, mid.id, to.id] },
           as: :json
    end
    assert_response :created

    route = JumpRoute.find(response.parsed_body['id'])
    assert_equal 'plotted', route.route_type
    assert_equal 'My Route', route.name
  end

  test 'save with valid bearer token creates a plotted JumpRoute' do
    from = build_star_system(50, 0)
    to = build_star_system(51, 0)

    assert_difference 'JumpRoute.count', 1 do
      post api_route_plan_save_url(campaign_slug: @campaign.slug),
           params: { name: 'Token Route', jump_range: 1, refueling: 'any',
                     from_id: from.id, to_id: to.id, system_ids: [from.id, to.id] },
           headers: { 'Authorization' => "Bearer #{@campaign.api_token}" },
           as: :json
    end
    assert_response :created
  end

  test 'systems excludes unsurveyed systems for anonymous requests and includes them for the referee' do
    build_star_system(60, 0, name: 'Zeta Prime', known: false, survey_index: 0)

    get api_route_plan_systems_url(campaign_slug: @campaign.slug, q: 'Zeta Prime'), as: :json
    assert_response :success
    assert_empty response.parsed_body

    sign_in_as users(:one)
    get api_route_plan_systems_url(campaign_slug: @campaign.slug, q: 'Zeta Prime'), as: :json
    assert_response :success
    assert_equal 1, response.parsed_body.size
  end
end
