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

  test 'parsecs lists a subsector\'s parsecs' do
    parsec = parsecs(:one)
    get api_parsecs_url(subsector_id: parsec.subsector.id), as: :json
    assert_response :success
    assert_includes response.parsed_body.map { |p| p['id'] }, parsec.id
  end

  test 'parsecs lists a viewport\'s parsecs' do
    parsec = parsecs(:one)
    get api_parsecs_url(ulx: parsec.x, uly: parsec.y, lrx: parsec.x, lry: parsec.y), as: :json
    assert_response :success
    assert_equal [parsec.id], response.parsed_body.map { |p| p['id'] }
  end

  test 'parsecs rejects a missing, competing or incomplete selection with the same message' do
    parsec = parsecs(:one)
    box = { ulx: parsec.x, uly: parsec.y, lrx: parsec.x, lry: parsec.y }
    bad_requests = {
      'none' => {},
      'sector and subsector' => { sector_id: parsec.sector_id, subsector_id: parsec.subsector.id },
      'sector and sector coordinates' => { sector_id: parsec.sector_id, sx: 1, sy: 1 },
      'sector and box' => { sector_id: parsec.sector_id }.merge(box),
      'subsector and sector coordinates' => { subsector_id: parsec.subsector.id, sx: 1, sy: 1 },
      'subsector and box' => { subsector_id: parsec.subsector.id }.merge(box),
      'sector coordinates and box' => { sx: 1, sy: 1 }.merge(box),
      'hx and hy without a sector' => { hx: 1, hy: 1 },
      'hx without hy' => { sx: 1, sy: 1, hx: 1 },
      'hy without hx' => { sx: 1, sy: 1, hy: 1 },
      'hx and hy with sector_id' => { sector_id: parsec.sector_id, hx: 1, hy: 1 },
      'hx and hy with subsector_id' => { subsector_id: parsec.subsector.id, hx: 1, hy: 1 },
      'hx and hy with a box' => { hx: 1, hy: 1 }.merge(box),
      'hx and hy with only sx' => { sx: 1, hx: 1, hy: 1 },
      'sx without sy' => { sx: 1 },
      'sy without sx' => { sy: 1 },
      'incomplete box' => { ulx: parsec.x, uly: parsec.y },
      'sector and incomplete box' => { sector_id: parsec.sector_id, ulx: parsec.x },
      'competing with an oversized box' => { sector_id: parsec.sector_id, ulx: 0, uly: 100, lrx: 100, lry: 0 }
    }

    bad_requests.each do |name, query|
      get api_parsecs_url(**query), as: :json
      assert_response :bad_request, name
      assert_equal Api::ParsecsController::SELECTION_ERROR, response.parsed_body['error'], name
    end
  end

  test 'parsecs lists a sector by coordinates, optionally narrowed to one hex' do
    parsec = parsecs(:one)  # sector (1, 1), hex 0101
    get api_parsecs_url(sx: 1, sy: 1), as: :json
    assert_response :success
    assert_includes response.parsed_body.map { |p| p['id'] }, parsec.id

    get api_parsecs_url(sx: 1, sy: 1, hx: 1, hy: 1), as: :json
    assert_response :success
    assert_equal [parsec.id], response.parsed_body.map { |p| p['id'] }
    assert_equal '0101', response.parsed_body.first['hex_code']
  end

  test 'parsecs returns an empty list for a hex with no parsec' do
    [{ sx: 1, sy: 1, hx: 99, hy: 99 }, { sx: 1, sy: 1, hx: 33, hy: 1 }, { sx: 500, sy: 500, hx: 1, hy: 1 }].each do |query|
      get api_parsecs_url(**query), as: :json
      assert_response :success, query.inspect
      assert_empty response.parsed_body, query.inspect
    end
  end

  test 'parsecs rejects an oversized bounding box' do
    get api_parsecs_url(ulx: 0, uly: 100, lrx: 100, lry: 0), as: :json
    assert_response :bad_request
    assert_match(/no larger than/, response.parsed_body['error'])
  end

  test 'parsecs returns not found for an unknown sector' do
    get api_parsecs_url(sector_id: 0), as: :json
    assert_response :not_found
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

  test 'map redirects to sign in without a session' do
    sign_out
    get api_map_url(ulx: 0, uly: 0, lrx: 1, lry: -1)
    assert_response :redirect
  end
end
