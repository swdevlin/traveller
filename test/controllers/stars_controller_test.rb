require 'test_helper'

class StarsControllerTest < AuthenticatedIntegrationTest
  setup do
    @star = stars(:star_one)
  end

  test 'should update star' do
    patch star_url(@star), params: { star: { mass: 1.6 } }
    assert_redirected_to star_url(@star)
  end

  test 'eccentricity change triggers orbit mechanics recalculation' do
    base = Rails.application.config.x.generator_service
    stub = stub_request(:post, "#{base}/orbit_mechanics")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { 'primaryStar' => { 'orbitSequence' => @star.orbit_sequence, 'stellarObjects' => [] } }.to_json)

    patch star_url(@star), params: { star: { eccentricity: 0.4 } }

    assert_requested stub
    assert_redirected_to star_url(@star)
  end

  test 'unrelated field change does not trigger orbit mechanics recalculation' do
    base = Rails.application.config.x.generator_service
    stub = stub_request(:post, "#{base}/orbit_mechanics")

    patch star_url(@star), params: { star: { mass: 1.6 } }

    assert_not_requested stub
  end

  test 'flash alert when orbit mechanics recalculation fails' do
    base = Rails.application.config.x.generator_service
    stub_request(:post, "#{base}/orbit_mechanics")
      .to_return(status: 400, headers: { 'Content-Type' => 'application/json' }, body: { error: 'bad tree' }.to_json)

    patch star_url(@star), params: { star: { eccentricity: 0.4 } }

    assert_redirected_to star_url(@star)
    assert_match(/could not be recalculated/, flash[:alert].to_s)
  end
end
