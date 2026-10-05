require 'test_helper'

class Api::ParsecsControllerTest < AuthenticatedIntegrationTest
  setup do
    @parsec = parsecs(:four)
  end

  test 'update with active session sets survey_index' do
    patch "/c/#{campaigns(:one).slug}/api/parsecs/#{@parsec.id}",
          params: { survey_index: 8 },
          as: :json

    assert_response :success
    assert_equal({ 'survey_index' => 8 }, response.parsed_body)
    @parsec.reload
    assert_equal 8, @parsec.survey_index
  end

  test 'update with valid bearer token sets survey_index' do
    sign_out
    patch "/c/#{campaigns(:one).slug}/api/parsecs/#{@parsec.id}",
          params: { survey_index: 5 },
          headers: { 'Authorization' => "Bearer #{campaigns(:one).api_token}" },
          as: :json

    assert_response :success
    @parsec.reload
    assert_equal 5, @parsec.survey_index
  end

  test 'update without credentials returns unauthorised' do
    sign_out
    patch "/c/#{campaigns(:one).slug}/api/parsecs/#{@parsec.id}",
          params: { survey_index: 5 },
          as: :json

    assert_response :unauthorized
  end

  test 'update with survey_index out of range returns unprocessable entity' do
    patch "/c/#{campaigns(:one).slug}/api/parsecs/#{@parsec.id}",
          params: { survey_index: 13 },
          as: :json

    assert_response :unprocessable_entity
    assert response.parsed_body.key?('errors')
  end

  test 'update with unknown parsec returns not found' do
    patch "/c/#{campaigns(:one).slug}/api/parsecs/0",
          params: { survey_index: 5 },
          as: :json

    assert_response :not_found
  end
end
