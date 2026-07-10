# frozen_string_literal: true

require 'test_helper'

class Api::TravelZonesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  test 'index returns all travel zones without authentication' do
    zone = TravelZone.create!(code: 'RTZ', name: 'Route Test Zone', colour: '#ff00ff')

    get api_travel_zones_url(campaign_slug: @campaign.slug), as: :json

    assert_response :success
    body = response.parsed_body
    assert body.is_a?(Array)
    entry = body.find { |z| z['id'] == zone.id }
    assert entry
    assert_equal 'RTZ', entry['code']
    assert_equal 'Route Test Zone', entry['name']
    assert_equal '#ff00ff', entry['colour']
  end
end
