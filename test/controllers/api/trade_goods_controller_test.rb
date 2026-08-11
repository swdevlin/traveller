# frozen_string_literal: true

require 'test_helper'

class Api::TradeGoodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @sector = Sector.create!(name: 'Trade Goods API Test Sector', x: 98, y: 98, abbreviation: 'Tga')
  end

  def build_star_system(x, y, **attrs)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    StarSystem.create!({ name: "System #{x},#{y}", parsec: parsec }.merge(attrs))
  end

  test 'availability is unauthorised without credentials' do
    system = build_star_system(0, 0)

    get api_trade_goods_availability_url(campaign_slug: @campaign.slug, id: system.id), as: :json

    assert_response :unauthorized
  end

  test 'availability returns the goods list and mints a seed when none is given' do
    sign_in_as users(:one)
    system = build_star_system(0, 0)

    get api_trade_goods_availability_url(campaign_slug: @campaign.slug, id: system.id), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal system.id, body['system']['id']
    assert_kind_of Array, body['trade_codes']
    assert_kind_of Integer, body['population']
    assert_kind_of Integer, body['seed']
    assert_kind_of Array, body['goods']
    refute_empty body['goods']
  end

  test 'availability with the same seed returns the same goods list' do
    sign_in_as users(:one)
    system = build_star_system(0, 0)

    first = get_availability(system, seed: 42)
    second = get_availability(system, seed: 42)

    assert_equal first['goods'], second['goods']
  end

  test 'availability returns unprocessable_entity when the id does not resolve' do
    sign_in_as users(:one)

    get api_trade_goods_availability_url(campaign_slug: @campaign.slug, id: 0), as: :json

    assert_response :unprocessable_entity
  end

  test 'prices is unauthorised without credentials' do
    system = build_star_system(0, 0)

    get api_trade_goods_prices_url(campaign_slug: @campaign.slug, id: system.id, direction: 'purchase'), as: :json

    assert_response :unauthorized
  end

  test 'prices with no d66s rolls every priceable good' do
    sign_in_as users(:one)
    system = build_star_system(0, 0)

    get api_trade_goods_prices_url(campaign_slug: @campaign.slug, id: system.id, direction: 'purchase',
                                    skill_effect: 2, counterpart_broker_skill: 1, other_dm: -1), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal 'purchase', body['direction']
    assert_equal 2, body['skill_effect']
    assert_equal 1, body['counterpart_broker_skill']
    assert_equal(-1, body['other_dm'])
    assert_equal 35, body['results'].length
    refute body['results'].any? { |r| r['d66'] == 66 }

    first = body['results'].first
    assert first.key?('name')
    assert_kind_of Array, first['modifiers']
    assert first['result'].key?('base_price')
    assert first['result'].key?('percent')
    assert first['result'].key?('price_per_ton')
    assert first['result']['qualifying_roll'].key?('rolls')
  end

  test 'prices with use_broker applies the Local Broker DM and fee' do
    sign_in_as users(:one)
    system = build_star_system(0, 0)

    get api_trade_goods_prices_url(campaign_slug: @campaign.slug, id: system.id, direction: 'purchase',
                                    d66s: [11], use_broker: 'true', broker_level: 3, broker_fee_percentage: 10),
        as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal true, body['use_broker']
    assert_equal 3, body['broker_level']
    assert_equal 10.0, body['broker_fee_percentage']

    result = body['results'].first['result']
    assert result.key?('net_price_per_ton')
    assert_equal 10.0, result['fee_percentage']
    assert_includes body['results'].first['modifiers'], { 'label' => 'Local Broker DM', 'value' => 5 }
  end

  test 'prices without use_broker defaults the campaign broker level and fee' do
    sign_in_as users(:one)
    system = build_star_system(0, 0)

    get api_trade_goods_prices_url(campaign_slug: @campaign.slug, id: system.id, direction: 'purchase', d66s: [11]),
        as: :json

    assert_response :success
    body = response.parsed_body

    refute body['use_broker']
    assert_equal 2, body['broker_level']
    assert_equal 10.0, body['broker_fee_percentage']
    assert_equal 0, body['results'].first['result']['fee_percentage']
  end

  test 'prices with explicit d66s only rolls those goods' do
    sign_in_as users(:one)
    system = build_star_system(0, 0)

    get api_trade_goods_prices_url(campaign_slug: @campaign.slug, id: system.id, direction: 'sale', d66s: [11, 21]), as: :json

    assert_response :success
    body = response.parsed_body

    assert_equal [11, 21], body['results'].map { |r| r['d66'] }
  end

  test 'prices returns unprocessable_entity when the id does not resolve' do
    sign_in_as users(:one)

    get api_trade_goods_prices_url(campaign_slug: @campaign.slug, id: 0, direction: 'purchase'), as: :json

    assert_response :unprocessable_entity
  end

  test 'prices returns unprocessable_entity for an invalid direction' do
    sign_in_as users(:one)
    system = build_star_system(0, 0)

    get api_trade_goods_prices_url(campaign_slug: @campaign.slug, id: system.id, direction: 'browse'), as: :json

    assert_response :unprocessable_entity
  end

  private

  def get_availability(system, seed:)
    get api_trade_goods_availability_url(campaign_slug: @campaign.slug, id: system.id, seed: seed), as: :json
    response.parsed_body
  end
end
