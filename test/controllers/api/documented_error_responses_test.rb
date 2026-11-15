# frozen_string_literal: true

require 'test_helper'

# Triggers the documented 401, 403, 404 and 422 responses that the endpoint
# tests do not reach. The contract-test observer in test_helper.rb validates
# every response here against openapi/openapi.yml, so each test fails if the
# response stops matching what the spec promises.
class Api::DocumentedErrorResponsesTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @base = "/c/#{@campaign.slug}/api"
    @token_headers = { 'Authorization' => "Bearer #{@campaign.api_token}" }
    @overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#112233')
  end

  # A signed-in user who does not referee the campaign.
  def sign_in_as_non_referee
    sign_in_as users(:two)
  end

  # ---- 403: signed in, but not the campaign's referee

  test 'referee tools are forbidden to a non-referee' do
    sign_in_as_non_referee

    %w[passenger_traffic passenger_traffic/system freight_traffic freight_traffic/system
       mail_traffic mail_traffic/system trade_goods/availability trade_goods/prices].each do |path|
      get "#{@base}/#{path}", as: :json
      assert_response :forbidden, "GET #{path}"
    end
  end

  test 'writes are forbidden to a non-referee' do
    sign_in_as_non_referee
    star_system = star_systems(:in_one)
    route = jump_routes(:one)

    patch "#{@base}/parsecs/#{parsecs(:one).id}", params: { survey_index: 3 }, as: :json
    assert_response :forbidden
    patch "#{@base}/star_systems/#{star_system.id}", params: { survey_index: 3 }, as: :json
    assert_response :forbidden
    patch "#{@base}/jump_routes/#{route.id}", params: { name: 'Renamed' }, as: :json
    assert_response :forbidden
    delete "#{@base}/jump_routes/#{route.id}", as: :json
    assert_response :forbidden
    post "#{@base}/route_plan/save", params: { system_ids: [star_system.id, star_systems(:in_two).id] }, as: :json
    assert_response :forbidden
  end

  test 'survey overlay writes are forbidden to a non-referee' do
    sign_in_as_non_referee

    post "#{@base}/survey_overlays", params: { name: 'New', colour: '#445566' }, as: :json
    assert_response :forbidden
    patch "#{@base}/survey_overlays/#{@overlay.id}", params: { name: 'Renamed' }, as: :json
    assert_response :forbidden
    patch "#{@base}/survey_overlays/#{@overlay.id}", params: { position: 1 }, as: :json
    assert_response :forbidden
  end

  test 'orbit maps are forbidden to a non-referee' do
    sign_in_as_non_referee
    star = stellar_objects(:primary_for_hierarchy)

    get "#{@base}/stars/#{star.id}/orbit_map"
    assert_response :forbidden
    get "#{@base}/stars/#{star.id}/orbit_map.webp"
    assert_response :forbidden
  end

  # ---- 401: no credentials at all

  test 'a star system rename without credentials is unauthorised' do
    patch "#{@base}/star_systems/#{star_systems(:in_one).id}", params: { survey_index: 3 }, as: :json
    assert_response :unauthorized
  end

  test 'a webp orbit map without credentials is unauthorised' do
    get "#{@base}/stars/#{stellar_objects(:primary_for_hierarchy).id}/orbit_map.webp"
    assert_response :unauthorized
  end

  test 'moving a survey overlay without credentials is unauthorised' do
    patch "#{@base}/survey_overlays/#{@overlay.id}", params: { position: 1 }, as: :json
    assert_response :unauthorized
  end

  # ---- 404: no such record

  test 'unknown records are not found' do
    get "#{@base}/subsectors/0", as: :json
    assert_response :not_found
    get "#{@base}/star_systems/0", as: :json
    assert_response :not_found
    get "#{@base}/stellar_objects/0", as: :json
    assert_response :not_found
  end

  test 'a webp orbit map for an unknown star is not found' do
    get "#{@base}/stars/0/orbit_map.webp", headers: @token_headers
    assert_response :not_found
  end

  # ---- 422: rejected values

  test 'ship traffic is unprocessable for a system with no main world' do
    system = star_systems(:in_one)
    system.update_columns(main_world_id: nil)

    get "#{@base}/star_systems/#{system.id}/ship_traffic", as: :json
    assert_response :unprocessable_entity
  end

  test 'a star system update with an invalid survey index is unprocessable' do
    patch "#{@base}/star_systems/#{star_systems(:in_one).id}",
          params: { survey_index: 99 }, headers: @token_headers, as: :json
    assert_response :unprocessable_entity
  end

  test 'a survey overlay update with a blank name is unprocessable' do
    patch "#{@base}/survey_overlays/#{@overlay.id}",
          params: { name: '' }, headers: @token_headers, as: :json
    assert_response :unprocessable_entity
  end

  test 'saving a route plan with no systems is unprocessable' do
    post "#{@base}/route_plan/save", params: { system_ids: [] }, headers: @token_headers, as: :json
    assert_response :unprocessable_entity
  end
end

# The hex map is an SVG rendered by the app's own controller, so it takes a
# session cookie, not the bearer token the rest of the API accepts.
class Api::DocumentedMapResponsesTest < AuthenticatedIntegrationTest
  test 'the map is an SVG, and an unchanged map is not modified' do
    get api_map_url(ulx: 0, uly: 0, lrx: 2, lry: -2)
    assert_response :success
    assert_equal 'image/svg+xml', response.media_type

    get api_map_url(ulx: 0, uly: 0, lrx: 2, lry: -2), headers: { 'If-None-Match' => response.headers['ETag'] }
    assert_response :not_modified
  end
end
