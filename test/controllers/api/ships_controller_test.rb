# frozen_string_literal: true

require 'test_helper'

class Api::ShipsControllerTest < AuthenticatedIntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  test 'index returns ships without token' do
    get api_ships_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success
    body = response.parsed_body
    assert body.is_a?(Array)
    assert body.any?
    ship = body.first
    assert ship.key?('id')
    assert ship.key?('name')
    assert ship.key?('jump_drive')
  end
end
