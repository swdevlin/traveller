# frozen_string_literal: true

require 'test_helper'

class Api::RoguesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  test 'requires a viewport' do
    get api_rogues_url(campaign_slug: @campaign.slug), as: :json

    assert_response :bad_request
  end

  test 'accepts a bounding box of exactly 16 columns by 20 rows' do
    get api_rogues_url(campaign_slug: @campaign.slug, ulx: 0, uly: 19, lrx: 15, lry: 0), as: :json

    assert_response :success
  end

  test 'rejects a bounding box more than 16 columns wide' do
    get api_rogues_url(campaign_slug: @campaign.slug, ulx: 0, uly: 19, lrx: 16, lry: 0), as: :json

    assert_response :bad_request
    assert_equal 'bounding box must be no larger than 16 columns by 20 rows', response.parsed_body['error']
  end

  test 'rejects a bounding box more than 20 rows tall' do
    get api_rogues_url(campaign_slug: @campaign.slug, ulx: 0, uly: 20, lrx: 15, lry: 0), as: :json

    assert_response :bad_request
  end

  test 'rejects both a sector and a bounding box' do
    get api_rogues_url(campaign_slug: @campaign.slug, sx: 1, sy: 1, ulx: 0, uly: 1000, lrx: 1000, lry: 0), as: :json

    assert_response :bad_request
    assert_match 'exactly one of', response.parsed_body['error']
  end

  test 'returns rogues in a parsec that also has a star system' do
    parsec = parsecs(:one)
    assert StarSystem.exists?(parsec: parsec)

    get api_rogues_url(campaign_slug: @campaign.slug, ulx: parsec.x, uly: parsec.y, lrx: parsec.x, lry: parsec.y), as: :json

    assert_response :success
    assert_includes response.parsed_body.pluck('parsec_id'), parsec.id
  end
end
