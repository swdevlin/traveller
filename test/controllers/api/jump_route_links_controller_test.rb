# frozen_string_literal: true

require 'test_helper'

class Api::JumpRouteLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @parsec = parsecs(:one)
    @bounds = { ulx: @parsec.x, uly: @parsec.y, lrx: @parsec.x, lry: @parsec.y }
  end

  test 'requires bounding box params' do
    get api_jump_route_links_url(campaign_slug: @campaign.slug), as: :json

    assert_response :bad_request
  end

  test 'index includes the jump_route_id for a link whose from_star_system is in bounds' do
    route = JumpRoute.create!(name: 'Network Route')
    link = JumpRouteLink.create!(jump_route: route, from_star_system: star_systems(:in_one), to_star_system: star_systems(:in_two))

    get api_jump_route_links_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    entry = response.parsed_body.find { |l| l['id'] == link.id }
    assert entry
    assert_equal route.id, entry['jump_route_id']
  end

  test 'index excludes a link with neither endpoint in bounds' do
    route = JumpRoute.create!(name: 'Network Route')
    link = JumpRouteLink.create!(jump_route: route, from_star_system: star_systems(:in_two), to_star_system: star_systems(:in_five))

    get api_jump_route_links_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    assert_nil response.parsed_body.find { |l| l['id'] == link.id }
  end
end
