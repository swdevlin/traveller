# frozen_string_literal: true

require 'test_helper'

class Api::StarMapControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @parsec = parsecs(:one)
    @bounds = { ulx: @parsec.x, uly: @parsec.y, lrx: @parsec.x, lry: @parsec.y }
  end

  test 'requires bounding box params' do
    get api_star_map_url(campaign_slug: @campaign.slug), as: :json

    assert_response :bad_request
  end

  test 'includes a visible system with its main world trade codes' do
    star_system = StarSystem.create!(name: 'Test System', parsec: @parsec, known: true)
    star = Star.create!(star_system: star_system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    main_world = TerrestrialPlanet.create!(
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      population_code: 6, government_code: 5, law_level_code: 5,
      tech_level_code: 8, starport_code: 'A',
      orbiting: star, orbit: 1.0
    )
    main_world.trade_codes = [trade_codes(:tc1), trade_codes(:tc2)]
    star_system.update!(main_world: main_world)

    get api_star_map_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    entry = response.parsed_body.find { |s| s['id'] == star_system.id }
    assert entry
    assert_equal %w[T1 T2], entry['trade_codes'].sort
  end

  test 'a system not known and below survey index 10 has no trade codes for an unauthenticated request' do
    star_system = StarSystem.create!(name: 'Unsurveyed System', parsec: @parsec, known: false, survey_index: 0)
    star = Star.create!(star_system: star_system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    main_world = TerrestrialPlanet.create!(
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      population_code: 6, government_code: 5, law_level_code: 5,
      tech_level_code: 8, starport_code: 'A',
      orbiting: star, orbit: 1.0
    )
    main_world.trade_codes = [trade_codes(:tc1)]
    star_system.update!(main_world: main_world)

    get api_star_map_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    entry = response.parsed_body.find { |s| s['id'] == star_system.id }
    assert entry
    assert_equal [], entry['trade_codes']
  end

  test 'strategic is only computed when display_mode requests it, trade_codes is unaffected either way' do
    star_system = StarSystem.create!(name: 'Strategic Test System', parsec: @parsec, known: true)
    star = Star.create!(star_system: star_system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    main_world = TerrestrialPlanet.create!(
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      population_code: 6, government_code: 5, law_level_code: 5,
      tech_level_code: 8, starport_code: 'A',
      orbiting: star, orbit: 1.0
    )
    main_world.trade_codes = [trade_codes(:tc1)]
    star_system.update!(main_world: main_world)

    get api_star_map_url(campaign_slug: @campaign.slug, **@bounds), as: :json
    assert_response :success
    entry = response.parsed_body.find { |s| s['id'] == star_system.id }
    assert_nil entry['strategic']
    assert_equal %w[T1], entry['trade_codes']

    get api_star_map_url(campaign_slug: @campaign.slug, display_mode: 'Strategic', **@bounds), as: :json
    assert_response :success
    entry = response.parsed_body.find { |s| s['id'] == star_system.id }
    assert entry['strategic']
    assert entry['strategic']['importance_tier']
    assert_equal %w[T1], entry['trade_codes']
  end
end
