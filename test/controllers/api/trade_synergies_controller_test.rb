# frozen_string_literal: true

require 'test_helper'

class Api::TradeSynergiesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @sector = Sector.create!(name: 'Trade Synergy Test Sector', x: 97, y: 97, abbreviation: 'Tsy')
  end

  def build_system(x, y, codes: [], gas_giants: 0, **attrs)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    system = StarSystem.create!({ name: "System #{x},#{y}", parsec: parsec }.merge(attrs))
    star = Star.create!(star_system: system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    world = TerrestrialPlanet.create!(
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      population_code: 6, government_code: 5, law_level_code: 5,
      tech_level_code: 8, starport_code: 'B', orbiting: star, orbit: 1.0
    )
    world.trade_codes = codes.map { |code| TradeCode.find_or_create_by!(code: code) { |tc| tc.definition = code } }
    system.update!(main_world: world)
    system.update_column(:gas_giant_count, gas_giants) # recalculated from stars on save, so set it last
    system
  end

  def get_synergies(system, **params)
    get api_star_system_trade_synergies_url(campaign_slug: @campaign.slug, id: system.id, **params), as: :json
  end

  test 'is unauthorised without credentials' do
    system = build_system(0, 0)

    get_synergies(system)

    assert_response :unauthorized
  end

  test 'returns not found for an unknown system' do
    sign_in_as users(:one)

    get api_star_system_trade_synergies_url(campaign_slug: @campaign.slug, id: 0), as: :json

    assert_response :not_found
  end

  test 'lists partners within the jump range with counts and goods in each direction' do
    sign_in_as users(:one)
    origin = build_system(0, 0, codes: %w[In], gas_giants: 1)
    partner = build_system(1, 0, codes: %w[Ni])

    get_synergies(origin, jump: 2)

    assert_response :success
    body = response.parsed_body
    assert_equal 2, body['jump']
    assert_equal origin.id, body['origin']['id']
    assert_equal true, body['origin']['gas_giant']
    assert_equal 'B', body['origin']['starport']

    row = body['partners'].find { it['id'] == partner.id }
    assert_equal 1, row['distance']
    assert_equal row['outbound_goods'].size, row['outbound_count']
    assert_equal row['outbound_goods'].sum { it['bonus'] }, row['outbound_bonus']
    assert_equal row['inbound_goods'].size, row['inbound_count']
    assert_operator row['outbound_count'], :>, 0
    assert row['outbound_goods'].any? { it['d66'] == 12 }
  end

  test 'excludes systems beyond the jump range and the origin itself' do
    sign_in_as users(:one)
    origin = build_system(0, 0, codes: %w[In])
    near = build_system(1, 0, codes: %w[Ni])
    far = build_system(3, 0, codes: %w[Ni])

    get_synergies(origin, jump: 1)

    ids = response.parsed_body['partners'].map { it['id'] }
    assert_includes ids, near.id
    refute_includes ids, far.id
    refute_includes ids, origin.id
  end

  test 'clamps jump to between 1 and 6 and defaults to 2' do
    sign_in_as users(:one)
    origin = build_system(0, 0)

    get_synergies(origin, jump: 99)
    assert_equal 6, response.parsed_body['jump']

    get_synergies(origin, jump: 0)
    assert_equal 1, response.parsed_body['jump']

    get_synergies(origin)
    assert_equal 2, response.parsed_body['jump']
  end

  test 'sorts partners by combined count then distance' do
    sign_in_as users(:one)
    origin = build_system(0, 0, codes: %w[In])
    build_system(1, 0, codes: [])
    build_system(2, 0, codes: %w[Ni])

    get_synergies(origin, jump: 2)

    partners = response.parsed_body['partners']
    assert_equal partners.sort_by { [-(it['outbound_count'] + it['inbound_count']), it['distance']] }.map { it['id'] },
                 partners.map { it['id'] }
  end
end
