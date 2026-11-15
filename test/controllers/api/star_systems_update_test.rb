# frozen_string_literal: true

require 'test_helper'

# PATCH /star_systems/:id : renaming a system and setting what the players know.
class Api::StarSystemsUpdateTest < AuthenticatedIntegrationTest
  setup do
    @campaign = campaigns(:one)
    @star_system = star_systems(:in_one)
    @url = "/c/#{@campaign.slug}/api/star_systems/#{@star_system.id}"
    @token_headers = { 'Authorization' => "Bearer #{@campaign.api_token}" }
  end

  test 'update with an active session sets known and survey_index' do
    patch @url, params: { known: true, survey_index: 8 }, as: :json

    assert_response :success
    assert_equal({ 'name' => 'In One', 'known' => true, 'survey_index' => 8 }, response.parsed_body)
    @star_system.reload
    assert @star_system.known?
    assert_equal 8, @star_system.survey_index
  end

  test 'update renames the system' do
    patch @url, params: { name: 'Zeta Prime' }, as: :json

    assert_response :success
    assert_equal 'Zeta Prime', response.parsed_body['name']
    assert_equal 'Zeta Prime', @star_system.reload.name
  end

  test 'update changes only the fields sent' do
    @star_system.update!(known: true, survey_index: 4)

    patch @url, params: { name: 'Zeta Prime' }, as: :json

    assert_response :success
    assert @star_system.reload.known?
    assert_equal 4, @star_system.survey_index
  end

  test 'update with the campaign API token succeeds' do
    sign_out

    patch @url, params: { name: 'Zeta Prime', survey_index: 5 }, headers: @token_headers, as: :json

    assert_response :success
    assert_equal 'Zeta Prime', @star_system.reload.name
    assert_equal 5, @star_system.survey_index
  end

  test 'update without credentials is unauthorised and changes nothing' do
    sign_out

    patch @url, params: { name: 'Zeta Prime', known: true }, as: :json

    assert_response :unauthorized
    assert_not_equal 'Zeta Prime', @star_system.reload.name
  end

  test 'update by a signed-in user who is not the referee is forbidden' do
    sign_out
    sign_in_as users(:two)

    patch @url, params: { name: 'Zeta Prime' }, as: :json

    assert_response :forbidden
    assert_not_equal 'Zeta Prime', @star_system.reload.name
  end

  test 'update with a survey_index out of range is unprocessable' do
    patch @url, params: { survey_index: 13 }, as: :json

    assert_response :unprocessable_entity
    assert response.parsed_body.key?('errors')
  end

  test 'update of an unknown star system is not found' do
    patch "/c/#{@campaign.slug}/api/star_systems/0", params: { known: true }, as: :json

    assert_response :not_found
  end
end
