require 'test_helper'

# GET /parsecs/:id : a parsec with the star system in it.
class Api::ParsecsLookupTest < AuthenticatedIntegrationTest
  setup do
    @parsec = parsecs(:one)  # x=32, y=40 → sector one: x=1, y=1 → hx=1, hy=1
  end

  def show_url(parsec)
    "/c/#{campaigns(:one).slug}/api/parsecs/#{parsec.id}"
  end

  test 'returns the parsec with its star system' do
    get show_url(@parsec), as: :json

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
    get show_url(@parsec), as: :json

    star_system = response.parsed_body['star_system']
    assert_equal 1, star_system['sector_x']
    assert_equal 1, star_system['sector_y']
    assert_equal 1, star_system['x']
    assert_equal 1, star_system['y']
    assert_equal 32, star_system['origin_x']
    assert_equal 40, star_system['origin_y']
  end

  test 'returns the parsec with no star system when the hex is empty' do
    get show_url(parsecs(:four)), as: :json  # no star system fixture

    assert_response :success
    assert_nil response.parsed_body['star_system']
    assert response.parsed_body.key?('survey_index')
  end

  test 'does not nest the parsec data inside a parsec key' do
    get show_url(@parsec), as: :json

    assert_not response.parsed_body.key?('parsec')
  end

  test 'returns not found for an unknown id' do
    get "/c/#{campaigns(:one).slug}/api/parsecs/0", as: :json

    assert_response :not_found
    assert_equal 'parsec not found', response.parsed_body['error']
  end

  test 'is available without signing in' do
    sign_out

    get show_url(@parsec), as: :json

    assert_response :success
  end
end
