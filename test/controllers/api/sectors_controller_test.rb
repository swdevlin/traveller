require 'test_helper'

class Api::SectorsControllerTest < ActionDispatch::IntegrationTest
  test 'returns all sectors' do
    get api_sectors_url, as: :json
    assert_response :success
    body = response.parsed_body
    assert body.is_a?(Array)
    assert body.any?
    sector = body.first
    assert sector.key?('id')
    assert sector.key?('name')
    assert sector.key?('x')
    assert sector.key?('y')
    assert sector.key?('abbreviation')
  end
end
