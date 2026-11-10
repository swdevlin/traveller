require 'test_helper'

class TravellerMapTest < ActiveSupport::TestCase
  test 'search returns UTF-8 strings' do
    body = '[{"name":"Ferré"}]'.b
    stub_request(:get, %r{travellermap\.com/api/search}).to_return(status: 200, body: body)

    result = TravellerMap.new.send(:search, term: 'Ferre')

    assert_equal Encoding::UTF_8, result.encoding
    assert_equal 'Ferré', JSON.parse(result).first['name']
  end

  test 'fetch returns UTF-8 strings' do
    stub_request(:get, %r{travellermap\.com/api/metadata}).to_return(status: 200, body: 'Ferré'.b)

    assert_equal Encoding::UTF_8, TravellerMap.new.send(:fetch, 'metadata').encoding
  end
end
