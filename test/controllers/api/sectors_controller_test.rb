require 'test_helper'

class Api::SectorsControllerTest < AuthenticatedIntegrationTest
  test 'returns all sectors' do
    sectors(:one).update!(tag_list: 'Frontier, Research')
    get api_sectors_url, as: :json
    assert_response :success
    body = response.parsed_body
    assert body.is_a?(Array)
    assert body.any?
    assert_equal ['Frontier', 'Research'], body.find { |item| item['id'] == sectors(:one).id }['tags']
    assert body.first['subsectors'].all? { |item| item['tags'].is_a?(Array) }
    sector = body.first
    assert sector.key?('id')
    assert sector.key?('name')
    assert sector.key?('x')
    assert sector.key?('y')
    assert sector.key?('abbreviation')
  end
end
