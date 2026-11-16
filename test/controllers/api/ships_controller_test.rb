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
    assert ship.key?('j_drive')
    assert ship.key?('m_drive')
  end

  test 'show returns a ship without token' do
    ship = ships(:one)

    get api_ship_url(ship, campaign_slug: @campaign.slug), as: :json

    assert_response :success
    assert_equal({ 'id' => ship.id, 'name' => ship.name, 'j_drive' => ship.jump_drive, 'm_drive' => ship.m_drive },
                 response.parsed_body.except('last_jump'))
  end

  test 'show returns not_found for an unknown ship' do
    get api_ship_url(0, campaign_slug: @campaign.slug), as: :json

    assert_response :not_found
    assert_equal 'ship not found', response.parsed_body['error']
  end

  test 'show includes the ship\'s most recent arrival as last_jump' do
    get api_ship_url(ships(:one), campaign_slug: @campaign.slug), as: :json

    assert_response :success
    assert_includes response.parsed_body['last_jump'].keys, 'parsec_id'
  end

  test 'index includes each ship\'s last_jump without a query per ship' do
    Ship.create!(name: 'Unlaunched', jump_drive: 1, m_drive: 1)
    get api_ships_url(campaign_slug: @campaign.slug), as: :json

    assert_response :success
    by_name = response.parsed_body.index_by { |s| s['name'] }
    assert_nil by_name['Unlaunched']['last_jump']
    assert_includes by_name[ships(:one).name]['last_jump'].keys, 'parsec_id'
  end

  test 'show returns a null last_jump for a ship that has not jumped' do
    ship = Ship.create!(name: 'Unlaunched', jump_drive: 1, m_drive: 1)
    get api_ship_url(ship, campaign_slug: @campaign.slug), as: :json

    assert_response :success
    assert response.parsed_body.key?('last_jump')
    assert_nil response.parsed_body['last_jump']
  end
end
