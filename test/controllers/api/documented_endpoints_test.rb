# frozen_string_literal: true

require 'test_helper'

# Exercises documented endpoints that have no other API test. The contract-test
# observer in test_helper.rb validates every response here against
# openapi/openapi.yml, so these tests mostly need to make a request and check
# the status; a response that drifts from the spec fails them.
class Api::DocumentedEndpointsTest < AuthenticatedIntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  test 'parsecs lists a sector\'s parsecs' do
    get api_parsecs_url(sector_id: parsecs(:one).sector_id), as: :json
    assert_response :success
    assert response.parsed_body.any?
  end

  test 'rogues lists rogue bodies in a viewport' do
    parsec = stellar_objects(:rogue).parsec
    get api_rogues_url(ulx: parsec.x, uly: parsec.y, lrx: parsec.x, lry: parsec.y), as: :json
    assert_response :success
  end

  test 'subsector_at returns not found for an empty coordinate' do
    get api_subsector_at_url(x: 999_999, y: 999_999), as: :json
    assert_response :not_found
  end

  test 'subsector_at returns the subsector path' do
    parsec = Parsec.all.detect(&:subsector)
    skip 'no fixture parsec has a subsector' unless parsec

    get api_subsector_at_url(x: parsec.x, y: parsec.y), as: :json
    assert_response :success
  end

  test 'search returns matches' do
    get api_search_url(q: 'sec'), as: :json
    assert_response :success
  end

  test 'search returns an empty list for short queries' do
    get api_search_url(q: 'a'), as: :json
    assert_response :success
    assert_equal [], response.parsed_body
  end

  test 'ship_traffic estimates traffic for a system with a main world' do
    system = StarSystem.create!(name: 'Traffic System', parsec: parsecs(:five), known: true)
    star = Star.create!(star_system: system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    main_world = TerrestrialPlanet.create!(
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5,
      population_code: 6, government_code: 5, law_level_code: 5,
      tech_level_code: 8, starport_code: 'A',
      orbiting: star, orbit: 1.0
    )
    system.update!(main_world: main_world)

    get "/c/#{@campaign.slug}/api/star_systems/#{system.id}/ship_traffic", as: :json
    assert_response :success
  end

  test 'ship_traffic returns not found for an unknown system' do
    get "/c/#{@campaign.slug}/api/star_systems/0/ship_traffic", as: :json
    assert_response :not_found
  end

  test 'last_jump returns the ship\'s most recent jump' do
    get last_jump_api_ship_url(ships(:one)), as: :json
    assert_response :success
  end

  test 'map redirects to sign in without a session' do
    sign_out
    get api_map_url(ulx: 0, uly: 0, lrx: 1, lry: -1)
    assert_response :redirect
  end
end
