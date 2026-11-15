# frozen_string_literal: true

require 'test_helper'

class Api::MapLabelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @parsec = parsecs(:one)
    @bounds = { ulx: @parsec.x, uly: @parsec.y, lrx: @parsec.x, lry: @parsec.y }
  end

  test 'requires bounding box params' do
    get api_map_labels_url(campaign_slug: @campaign.slug), as: :json

    assert_response :bad_request
  end

  test 'referee sees a known label with full content' do
    @parsec.update!(label: 'Known label', label_colour: '#112233', visible: true, known: true)
    sign_in_as users(:one)

    get api_map_labels_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    entry = response.parsed_body.find { |l| l['id'] == @parsec.id }
    assert_equal 'Known label', entry['text']
    assert_equal '#112233', entry['colour']
    assert entry['known']
  end

  test 'referee sees an unknown label with full content' do
    @parsec.update!(label: 'Draft not yet known', visible: true, known: false)
    sign_in_as users(:one)

    get api_map_labels_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    entry = response.parsed_body.find { |l| l['id'] == @parsec.id }
    assert_equal 'Draft not yet known', entry['text']
    assert_not entry['known']
  end

  test 'unauthenticated request sees content only for known labels' do
    @parsec.update!(label: 'Known label', visible: true, known: true)

    get api_map_labels_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    entry = response.parsed_body.find { |l| l['id'] == @parsec.id }
    assert_equal 'Known label', entry['text']
  end

  test 'unauthenticated request never receives text for an unknown label' do
    @parsec.update!(label: 'Secret referee note', visible: true, known: false)

    get api_map_labels_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    entry = response.parsed_body.find { |l| l['id'] == @parsec.id }
    assert_nil entry['text']
    assert_nil entry['colour']
    assert_not entry['known']
    assert_not_includes response.body, 'Secret referee note'
  end

  test 'a visible: false label is omitted for everyone, including the referee' do
    @parsec.update!(label: 'Draft', visible: false, known: true)
    sign_in_as users(:one)

    get api_map_labels_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    assert_nil response.parsed_body.find { |l| l['id'] == @parsec.id }
  end

  test 'a parsec with no label is omitted' do
    @parsec.update!(label: nil)
    sign_in_as users(:one)

    get api_map_labels_url(campaign_slug: @campaign.slug, **@bounds), as: :json

    assert_response :success
    assert_nil response.parsed_body.find { |l| l['id'] == @parsec.id }
  end

  test 'accepts a bounding box of exactly 16 columns by 20 rows' do
    get api_map_labels_url(campaign_slug: @campaign.slug, ulx: 0, uly: 19, lrx: 15, lry: 0), as: :json

    assert_response :success
  end

  test 'rejects a bounding box more than 16 columns wide' do
    get api_map_labels_url(campaign_slug: @campaign.slug, ulx: 0, uly: 19, lrx: 16, lry: 0), as: :json

    assert_response :bad_request
    assert_equal 'bounding box must be no larger than 16 columns by 20 rows', response.parsed_body['error']
  end

  test 'rejects a bounding box more than 20 rows tall' do
    get api_map_labels_url(campaign_slug: @campaign.slug, ulx: 0, uly: 20, lrx: 15, lry: 0), as: :json

    assert_response :bad_request
  end

  test 'the box is ignored when a sector is given' do
    get api_map_labels_url(campaign_slug: @campaign.slug, sx: 1, sy: 1, ulx: 0, uly: 1000, lrx: 1000, lry: 0), as: :json

    assert_response :success
  end
end
