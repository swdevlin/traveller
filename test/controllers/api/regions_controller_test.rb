# frozen_string_literal: true

require 'test_helper'

class Api::RegionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @parsec_one = parsecs(:one)
  end

  test 'requires bounding box params' do
    get api_regions_url(campaign_slug: @campaign.slug), as: :json

    assert_response :bad_request
  end

  test 'only returns regions that intersect the requested bounding box' do
    bounds = { ulx: @parsec_one.x, uly: @parsec_one.y, lrx: @parsec_one.x, lry: @parsec_one.y }

    get api_regions_url(campaign_slug: @campaign.slug, **bounds), as: :json

    assert_response :success
    ids = response.parsed_body.map { |r| r['id'] }
    assert_includes ids, regions(:one).id
    assert_not_includes ids, regions(:two).id
  end

  test 'hexes and border_hexes are clipped to the padded viewport' do
    bounds = { ulx: @parsec_one.x, uly: @parsec_one.y, lrx: @parsec_one.x, lry: @parsec_one.y }

    get api_regions_url(campaign_slug: @campaign.slug, **bounds), as: :json

    assert_response :success
    region = response.parsed_body.find { |r| r['id'] == regions(:one).id }

    hexes = region['hexes'].map { |h| [h['x'], h['y']] }
    border_hexes = region['border_hexes'].map { |h| [h['x'], h['y']] }

    assert_includes hexes, [parsecs(:one).x, parsecs(:one).y]
    assert_includes hexes, [parsecs(:four).x, parsecs(:four).y]
    assert_not_includes hexes, [parsecs(:three).x, parsecs(:three).y]
    assert_not_includes hexes, [parsecs(:five).x, parsecs(:five).y]

    assert_includes border_hexes, [parsecs(:four).x, parsecs(:four).y]
    assert_not_includes border_hexes, [parsecs(:one).x, parsecs(:one).y]
    assert_not_includes border_hexes, [parsecs(:five).x, parsecs(:five).y]
  end
end
