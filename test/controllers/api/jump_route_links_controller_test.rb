# frozen_string_literal: true

require 'test_helper'

class Api::JumpRouteLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  test 'index includes the jump_route_id for each link' do
    route = JumpRoute.create!(name: 'Network Route')
    link = JumpRouteLink.create!(jump_route: route, from_star_system: star_systems(:in_one), to_star_system: star_systems(:in_two))

    get api_jump_route_links_url(campaign_slug: @campaign.slug), as: :json

    assert_response :success
    entry = response.parsed_body.find { |l| l['id'] == link.id }
    assert entry
    assert_equal route.id, entry['jump_route_id']
  end
end
