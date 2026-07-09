require 'test_helper'

class Api::SolarSystemControllerTest < AuthenticatedIntegrationTest
  setup do
    @star_system = star_systems(:in_one)  # parsec one: x=32, y=40 → sector one: x=1, y=1 → hx=1, hy=1
  end

  test 'returns single star system by sector and hex coordinates' do
    get api_starsystem_url(sx: 1, sy: 1, hx: 1, hy: 1), as: :json
    assert_response :success
    body = response.parsed_body
    assert_equal 1, body['sector_x']
    assert_equal 1, body['sector_y']
    assert_equal 1, body['x']
    assert_equal 1, body['y']
    assert_equal 32, body['origin_x']
    assert_equal 40, body['origin_y']
  end

  test 'returns 404 for non-existent hex' do
    get api_starsystem_url(sx: 1, sy: 1, hx: 99, hy: 99), as: :json
    assert_response :not_found
  end

  test 'returns 400 when parameters missing' do
    get api_starsystem_url, as: :json
    assert_response :bad_request
  end
end
