require 'test_helper'

# GET /parsecs/lookup : what is at a hex, addressed by sector and hex.
class Api::ParsecsLookupTest < AuthenticatedIntegrationTest
  setup do
    @parsec = parsecs(:one)  # x=32, y=40 → sector one: x=1, y=1 → hx=1, hy=1
  end

  test 'returns the parsec with its star system' do
    get api_parsecs_lookup_url(sx: 1, sy: 1, hx: 1, hy: 1), as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal @parsec.id, body['id']
    assert_equal '0101', body['hex_code']
    assert_equal 32, body['x']
    assert_equal 40, body['y']
    assert body.key?('survey_index')
    assert_includes @parsec.star_systems.pluck(:id), body.dig('star_system', 'id')
  end

  test 'the nested star system is positioned by sector and hex' do
    get api_parsecs_lookup_url(sx: 1, sy: 1, hx: 1, hy: 1), as: :json

    star_system = response.parsed_body['star_system']
    assert_equal 1, star_system['sector_x']
    assert_equal 1, star_system['sector_y']
    assert_equal 1, star_system['x']
    assert_equal 1, star_system['y']
    assert_equal 32, star_system['origin_x']
    assert_equal 40, star_system['origin_y']
  end

  test 'returns the parsec with no star system when the hex is empty' do
    get api_parsecs_lookup_url(sx: 1, sy: 1, hx: 1, hy: 2), as: :json  # parsec four, no star system fixture

    assert_response :success
    body = response.parsed_body
    assert_nil body['star_system']
    assert_equal parsecs(:four).id, body['id']
    assert body.key?('survey_index')
  end

  test 'does not nest the parsec data inside a parsec key' do
    get api_parsecs_lookup_url(sx: 1, sy: 1, hx: 1, hy: 1), as: :json

    assert_not response.parsed_body.key?('parsec')
  end

  test 'returns 404 for a hex that does not exist' do
    get api_parsecs_lookup_url(sx: 1, sy: 1, hx: 99, hy: 99), as: :json

    assert_response :not_found
    assert_equal 'parsec not found', response.parsed_body['error']
  end

  test 'returns 404 for a sector that does not exist' do
    get api_parsecs_lookup_url(sx: 500, sy: 500, hx: 1, hy: 1), as: :json

    assert_response :not_found
  end

  test 'returns 400 when parameters are missing' do
    get api_parsecs_lookup_url, as: :json

    assert_response :bad_request
    assert_equal 'sx, sy, hx, hy required', response.parsed_body['error']
  end

  test 'returns 400 when only some parameters are given' do
    get api_parsecs_lookup_url(sx: 1, sy: 1, hx: 1), as: :json

    assert_response :bad_request
  end

  test 'is available without signing in' do
    sign_out

    get api_parsecs_lookup_url(sx: 1, sy: 1, hx: 1, hy: 1), as: :json

    assert_response :success
  end
end
