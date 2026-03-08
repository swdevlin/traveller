require 'test_helper'

class Api::SolarSystemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @star_system = star_systems(:in_one)   # parsec one: x=32, y=40 → sector one: x=1, y=1 → hx=1, hy=1
  end

  test 'returns star systems for a sector' do
    get api_solarsystems_url(sx: 1, sy: 1), as: :json
    assert_response :success
    body = response.parsed_body
    assert body.is_a?(Array)
    ids = body.map { |s| s['id'] }
    assert_includes ids, @star_system.id
  end

  test 'returned system has expected fields' do
    get api_solarsystems_url(sx: 1, sy: 1), as: :json
    assert_response :success
    system = response.parsed_body.find { |s| s['id'] == @star_system.id }
    assert_not_nil system
    %w[id name survey_index origin_x origin_y x y sector_x sector_y sector_name
       allegiance bases remarks star_count gas_giant_count].each do |field|
      assert system.key?(field), "missing field: #{field}"
    end
  end

  test 'returns star systems for a bounding box' do
    get api_solarsystems_url(ulx: 32, uly: 40, lrx: 63, lry: 1), as: :json
    assert_response :success
    assert response.parsed_body.is_a?(Array)
  end

  test 'returns 400 when no coordinates given' do
    get api_solarsystems_url, as: :json
    assert_response :bad_request
  end
end
