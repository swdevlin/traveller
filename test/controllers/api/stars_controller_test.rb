require 'test_helper'

class Api::StarsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @star_system = star_systems(:in_one)  # parsec one: x=32, y=40 → sector one: x=1, y=1
  end

  test 'returns star systems with expected fields' do
    get api_stars_url(sx: 1, sy: 1), as: :json
    assert_response :success
    body = response.parsed_body
    assert body.is_a?(Array)
    system = body.find { |s| s['id'] == @star_system.id }
    assert_not_nil system
    assert system.key?('tech_level'), 'missing tech_level field'
    assert system.key?('native_sophont'), 'missing native_sophont field'
    assert system.key?('extinct_sophont'), 'missing extinct_sophont field'
    assert system.key?('stars'), 'missing stars field'
    assert_not system.key?('bases'), 'should not include bases'
    assert_not system.key?('remarks'), 'should not include remarks'
  end

  test 'returns 400 when no coordinates given' do
    get api_stars_url, as: :json
    assert_response :bad_request
  end

  test 'updates survey_index on a star system' do
    patch api_star_url(@star_system), params: { star: { survey_index: 5 } }, as: :json
    assert_response :success
    assert_equal 5, @star_system.reload.survey_index
  end

  test 'returns 404 for non-existent star system' do
    patch api_star_url(id: 0), params: { star: { survey_index: 5 } }, as: :json
    assert_response :not_found
  end
end
