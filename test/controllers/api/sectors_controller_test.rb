# frozen_string_literal: true

require 'test_helper'

class Api::SectorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    sign_in_as @campaign.referee
  end

  def create_sector_with_subsectors(x:, y:, subsector_count:)
    sector = Sector.create!(x: x, y: y, name: "Sector #{x}/#{y}", skip_subsector_creation: true)
    sector.tag_names = ['sector-tag']
    subsector_count.times do |i|
      subsector = Subsector.create!(sector: sector, x: i + 1, y: 1, name: "Sub #{i}")
      subsector.tag_names = ['subsector-tag']
    end
    sector
  end

  test 'index returns sectors with their subsector summaries' do
    sector = create_sector_with_subsectors(x: 101, y: 1, subsector_count: 2)

    get api_sectors_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success

    body = response.parsed_body.find { |s| s['id'] == sector.id }
    assert_equal ['sector-tag'], body['tags']
    assert_equal 2, body['subsectors'].length
    assert_equal %w[id name x y], body['subsectors'].first.keys.sort
  end

  test 'index includes survey and classified records for the referee' do
    sector = create_sector_with_subsectors(x: 105, y: 1, subsector_count: 1)
    sector.update!(player_notes: 'Sector **survey**', referee_notes: 'Sector secret')

    get api_sectors_url(campaign_slug: @campaign.slug), as: :json
    body = response.parsed_body.find { |s| s['id'] == sector.id }

    assert_equal 'Sector **survey**', body['survey_records']
    assert_not body.key?('survey_records_html')
    assert_not body.key?('classified_records_html')
    assert_equal 'Sector secret', body['classified_records']
  end

  test 'index withholds classified records and tags from a non-referee' do
    sector = create_sector_with_subsectors(x: 106, y: 1, subsector_count: 1)
    sector.update!(player_notes: 'Sector survey', referee_notes: 'Sector secret')

    sign_in_as users(:two)
    get api_sectors_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success
    body = response.parsed_body.find { |s| s['id'] == sector.id }

    assert_equal 'Sector survey', body['survey_records']
    assert_equal [], body['tags']
    assert body.key?('classified_records')
    assert_nil body['classified_records']
    assert_not body.key?('survey_records_html')
    assert_not body.key?('classified_records_html')
    assert_not_includes response.body, 'secret'
  end

  test 'does not issue a query per sector or per subsector' do
    create_sector_with_subsectors(x: 102, y: 1, subsector_count: 1)

    queries_for_one = assert_queries_count do
      get api_sectors_url(campaign_slug: @campaign.slug), as: :json
    end

    create_sector_with_subsectors(x: 103, y: 1, subsector_count: 3)
    create_sector_with_subsectors(x: 104, y: 1, subsector_count: 3)

    queries_for_many = assert_queries_count do
      get api_sectors_url(campaign_slug: @campaign.slug), as: :json
    end

    assert_equal queries_for_one, queries_for_many
  end

  test 'index returns 404 for an unknown campaign' do
    get api_sectors_url(campaign_slug: 'no-such-campaign'), as: :json
    assert_response :not_found
  end
end
