# frozen_string_literal: true

require 'test_helper'

class Api::PassengerTrafficControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @sector = Sector.create!(name: 'Passenger Traffic API Test Sector', x: 98, y: 98, abbreviation: 'Pta')
  end

  def build_star_system(x, y, **attrs)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    StarSystem.create!({ name: "System #{x},#{y}", parsec: parsec }.merge(attrs))
  end

  test 'calculate is unauthorised without credentials' do
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get api_passenger_traffic_url(campaign_slug: @campaign.slug, from_id: from.id, to_id: to.id), as: :json

    assert_response :unauthorized
  end

  test 'calculate returns the full JSON shape for an authenticated referee' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get api_passenger_traffic_url(campaign_slug: @campaign.slug, from_id: from.id, to_id: to.id,
                                   broker_effect: 2, chief_steward_skill: 1, referee_modifier: -1), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal from.id, body['from']['id']
    assert_equal to.id, body['to']['id']
    assert_equal 4, body['parsec_distance']
    assert_equal 2, body['broker_effect']
    assert_equal 1, body['chief_steward_skill']
    assert_equal(-1, body['referee_modifier'])
    assert_kind_of Array, body['shared_modifiers']

    %w[low basic middle high].each do |type|
      result = body['passenger_types'][type]
      assert result.key?('passengers'), type
      assert result.key?('modifiers'), type
      assert result['qualifying_roll'].key?('rolls'), type
      assert result.key?('count_roll'), type
    end
  end

  test 'calculate works with a valid bearer token' do
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get api_passenger_traffic_url(campaign_slug: @campaign.slug, from_id: from.id, to_id: to.id),
        headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json

    assert_response :success
  end

  test 'calculate returns unprocessable_entity when from and to are the same system' do
    sign_in_as users(:one)
    system = build_star_system(10, 0)

    get api_passenger_traffic_url(campaign_slug: @campaign.slug, from_id: system.id, to_id: system.id), as: :json

    assert_response :unprocessable_entity
  end

  test 'calculate returns unprocessable_entity when a system id does not resolve' do
    sign_in_as users(:one)
    from = build_star_system(20, 0)

    get api_passenger_traffic_url(campaign_slug: @campaign.slug, from_id: from.id, to_id: 0), as: :json

    assert_response :unprocessable_entity
  end

  test 'system is unauthorised without credentials' do
    system = build_star_system(30, 0)

    get api_passenger_traffic_system_url(campaign_slug: @campaign.slug, id: system.id), as: :json

    assert_response :unauthorized
  end

  test 'system returns the uwp and modifiers for a single system' do
    sign_in_as users(:one)
    system = build_star_system(30, 0)

    get api_passenger_traffic_system_url(campaign_slug: @campaign.slug, id: system.id), as: :json

    assert_response :success
    body = response.parsed_body

    assert body.key?('uwp')
    assert_kind_of Array, body['trade_codes']
    assert body.key?('travel_zone')
    assert_kind_of Array, body['modifiers']
  end

  test 'system returns unprocessable_entity when the id does not resolve' do
    sign_in_as users(:one)

    get api_passenger_traffic_system_url(campaign_slug: @campaign.slug, id: 0), as: :json

    assert_response :unprocessable_entity
  end
end
