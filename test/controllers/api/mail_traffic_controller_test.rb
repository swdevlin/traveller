# frozen_string_literal: true

require 'test_helper'

class Api::MailTrafficControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @sector = Sector.create!(name: 'Mail Traffic API Test Sector', x: 97, y: 97, abbreviation: 'Mta')
  end

  def build_star_system(x, y, **attrs)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    StarSystem.create!({ name: "System #{x},#{y}", parsec: parsec }.merge(attrs))
  end

  test 'calculate is unauthorised without credentials' do
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get api_mail_traffic_url(campaign_slug: @campaign.slug, from_id: from.id, to_id: to.id), as: :json

    assert_response :unauthorized
  end

  test 'calculate returns the full JSON shape for an authenticated referee' do
    sign_in_as users(:one)
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get api_mail_traffic_url(campaign_slug: @campaign.slug, from_id: from.id, to_id: to.id,
                              ship_armed: '1', naval_or_scout_rank: 2, soc_dm: 1, referee_modifier: -1), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal from.id, body['from']['id']
    assert_equal to.id, body['to']['id']
    assert_equal 4, body['parsec_distance']
    assert body.key?('freight_traffic_dm')
    assert_equal true, body['ship_armed']
    assert_equal 2, body['naval_or_scout_rank']
    assert_equal 1, body['soc_dm']
    assert_equal(-1, body['referee_modifier'])
    assert_kind_of Array, body['modifiers']

    result = body['result']
    assert result.key?('available')
    assert result.key?('containers')
    assert result.key?('total_tons')
    assert result.key?('total_payment')
    assert result['qualifying_roll'].key?('rolls')
    assert result.key?('containers_roll')
  end

  test 'calculate works with a valid bearer token' do
    from = build_star_system(0, 0)
    to   = build_star_system(4, 0)

    get api_mail_traffic_url(campaign_slug: @campaign.slug, from_id: from.id, to_id: to.id),
        headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json

    assert_response :success
  end

  test 'calculate returns unprocessable_entity when from and to are the same system' do
    sign_in_as users(:one)
    system = build_star_system(10, 0)

    get api_mail_traffic_url(campaign_slug: @campaign.slug, from_id: system.id, to_id: system.id), as: :json

    assert_response :unprocessable_entity
  end

  test 'calculate returns unprocessable_entity when a system id does not resolve' do
    sign_in_as users(:one)
    from = build_star_system(20, 0)

    get api_mail_traffic_url(campaign_slug: @campaign.slug, from_id: from.id, to_id: 0), as: :json

    assert_response :unprocessable_entity
  end

  test 'system is unauthorised without credentials' do
    system = build_star_system(30, 0)

    get api_mail_traffic_system_url(campaign_slug: @campaign.slug, id: system.id), as: :json

    assert_response :unauthorized
  end

  test 'system returns the uwp and modifiers for a single system' do
    sign_in_as users(:one)
    system = build_star_system(30, 0)

    get api_mail_traffic_system_url(campaign_slug: @campaign.slug, id: system.id), as: :json

    assert_response :success
    body = response.parsed_body

    assert body.key?('uwp')
    assert_kind_of Array, body['modifiers']
  end

  test 'system returns unprocessable_entity when the id does not resolve' do
    sign_in_as users(:one)

    get api_mail_traffic_system_url(campaign_slug: @campaign.slug, id: 0), as: :json

    assert_response :unprocessable_entity
  end
end
