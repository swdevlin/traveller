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
    assert ship.key?('m_drive')
  end

  test 'show returns a ship without token' do
    ship = ships(:one)

    get api_ship_url(ship, campaign_slug: @campaign.slug), as: :json

    assert_response :success
    assert_equal({ 'id' => ship.id, 'name' => ship.name, 'jump_drive' => ship.jump_drive, 'm_drive' => ship.m_drive },
                 response.parsed_body)
  end

  test 'show returns not_found for an unknown ship' do
    get api_ship_url(0, campaign_slug: @campaign.slug), as: :json

    assert_response :not_found
    assert_equal 'ship not found', response.parsed_body['error']
  end

  test 'last_jump returns the ship\'s most recent arrival' do
    get last_jump_api_ship_url(ships(:one), campaign_slug: @campaign.slug), as: :json

    assert_response :success
    assert_includes response.parsed_body.keys, 'parsec_id'
  end

  test 'last_jump returns not_found for an unknown ship' do
    get last_jump_api_ship_url(0, campaign_slug: @campaign.slug), as: :json

    assert_response :not_found
    assert_equal 'ship not found', response.parsed_body['error']
  end
end
