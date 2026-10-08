require 'test_helper'

class MapServiceTest < ActiveSupport::TestCase
  setup do
    @url = "#{Rails.application.config.x.map_service.chomp('/')}/map"
    @planet = { 'id' => 1, 'size_code' => '2', 'atmosphere' => { 'code' => 0 } }
  end

  test 'render posts the planet JSON unwrapped with the seed header and returns svg and seed' do
    stub = stub_request(:post, @url)
      .with(body: @planet.to_json, headers: { 'Content-Type' => 'application/json', 'X-Planet-Seed' => 'check' })
      .to_return(status: 200, headers: { 'Content-Type' => 'image/svg+xml', 'X-Planet-Seed' => 'check' }, body: '<svg/>')

    rendered = MapService.new.render(@planet, seed: 'check')

    assert_requested stub
    assert_equal '<svg/>', rendered.svg
    assert_equal 'check', rendered.seed
  end

  test 'render omits the seed header when no seed is given' do
    stub = stub_request(:post, @url)
      .with { |req| !req.headers.key?('X-Planet-Seed') }
      .to_return(status: 200, headers: { 'X-Planet-Seed' => 'random-seed' }, body: '<svg/>')

    assert_equal 'random-seed', MapService.new.render(@planet).seed
    assert_requested stub
  end

  test 'render raises with the status and the error message on a non-200 response' do
    stub_request(:post, @url).to_return(status: 422, body: { error: 'Size 0 worlds cannot be mapped' }.to_json)

    error = assert_raises(MapService::Error) { MapService.new.render(@planet) }

    assert_equal 422, error.status
    assert_equal 'Size 0 worlds cannot be mapped', error.api_message
    assert_match(/422.*Size 0 worlds cannot be mapped/, error.message)
  end

  test 'render keeps a non-JSON error body in the message' do
    stub_request(:post, @url).to_return(status: 502, body: '<html>Bad gateway</html>')

    error = assert_raises(MapService::Error) { MapService.new.render(@planet) }

    assert_match(/Bad gateway/, error.message)
  end
end
