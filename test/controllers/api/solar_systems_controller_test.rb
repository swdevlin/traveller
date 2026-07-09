require 'test_helper'

class Api::SolarSystemsControllerTest < AuthenticatedIntegrationTest
  setup do
    @star_system = star_systems(:in_one)   # parsec one: x=32, y=40 → sector one: x=1, y=1 → hx=1, hy=1
  end

  test 'returns star systems for a sector' do
    get api_starsystems_url(sx: 1, sy: 1), as: :json
    assert_response :success
    body = response.parsed_body
    assert body.is_a?(Array)
    ids = body.map { |s| s['id'] }
    assert_includes ids, @star_system.id
  end

  test 'returned system has expected fields' do
    get api_starsystems_url(sx: 1, sy: 1), as: :json
    assert_response :success
    system = response.parsed_body.find { |s| s['id'] == @star_system.id }
    assert_not_nil system
    %w[id name survey_index origin_x origin_y x y sector_x sector_y sector_name
       allegiance bases remarks star_count gas_giant_count].each do |field|
      assert system.key?(field), "missing field: #{field}"
    end
  end

  test 'returns star systems for a bounding box' do
    get api_starsystems_url(ulx: 32, uly: 40, lrx: 63, lry: 1), as: :json
    assert_response :success
    assert response.parsed_body.is_a?(Array)
  end

  test 'returns 400 when no coordinates given' do
    get api_starsystems_url, as: :json
    assert_response :bad_request
  end

  test 'update with active session sets known and survey_index' do
    patch "/c/#{campaigns(:one).slug}/api/star_systems/#{@star_system.id}",
          params: { known: true, survey_index: 8 },
          as: :json

    assert_response :success
    assert_equal({ 'known' => true, 'survey_index' => 8 }, response.parsed_body)
    @star_system.reload
    assert @star_system.known?
    assert_equal 8, @star_system.survey_index
  end

  test 'update with valid bearer token sets known and survey_index' do
    sign_out
    patch "/c/#{campaigns(:one).slug}/api/star_systems/#{@star_system.id}",
          params: { known: true, survey_index: 5 },
          headers: { 'Authorization' => "Bearer #{campaigns(:one).api_token}" },
          as: :json

    assert_response :success
    @star_system.reload
    assert @star_system.known?
    assert_equal 5, @star_system.survey_index
  end

  test 'update without credentials returns unauthorised' do
    sign_out
    patch "/c/#{campaigns(:one).slug}/api/star_systems/#{@star_system.id}",
          params: { known: true },
          as: :json

    assert_response :unauthorized
  end

  test 'update with survey_index out of range returns unprocessable entity' do
    patch "/c/#{campaigns(:one).slug}/api/star_systems/#{@star_system.id}",
          params: { survey_index: 13 },
          as: :json

    assert_response :unprocessable_entity
    assert response.parsed_body.key?('errors')
  end

  test 'update for unknown star system returns not found' do
    patch "/c/#{campaigns(:one).slug}/api/star_systems/0",
          params: { known: true },
          as: :json

    assert_response :not_found
  end
end
