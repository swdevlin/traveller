require 'test_helper'

class Api::TagPrivacyTest < ActionDispatch::IntegrationTest
  SECRET_TAG = 'Private referee tag 29718'

  setup do
    @campaign = campaigns(:one)
    @system = star_systems(:in_one)
    @body = gas_giants(:small)
    @body.update!(star_system: @system)
    @system.update!(known: true)
    [sectors(:one), subsectors(:subsector_1_1), @system, @body, regions(:one), stars(:star_one)].each do |record|
      record.update!(tag_names: [SECRET_TAG])
    end
    self.default_url_options = { campaign_slug: @campaign.slug }
    @endpoints = [
      api_sectors_url,
      api_subsector_url(subsectors(:subsector_1_1)),
      "/c/#{@campaign.slug}/api/parsecs/#{parsecs(:one).id}",
      "/c/#{@campaign.slug}/api/star_systems/#{@system.id}",
      "/c/#{@campaign.slug}/api/stellar_objects/#{@body.id}",
      api_star_map_url(sx: 1, sy: 1),
      api_regions_url(sx: 1, sy: 1)
    ]
  end

  test 'public API responses never contain tags' do
    @endpoints.each do |url|
      get url, as: :json
      assert_response :success
      assert_not_includes response.body, SECRET_TAG, url
    end
  end

  test 'a player or another campaign referee cannot see tags' do
    sign_in_as users(:two)
    @endpoints.each do |url|
      get url, as: :json
      assert_response :success
      assert_not_includes response.body, SECRET_TAG, url
    end
  end

  test 'the campaign referee can see tags in API responses' do
    sign_in_as users(:one)
    @endpoints.each do |url|
      get url, as: :json
      assert_response :success
      assert_includes response.body, SECRET_TAG, url
    end
  end

  test 'campaign API tokens retain referee tag access' do
    get api_sectors_url, headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json
    assert_response :success
    assert_includes response.body, SECRET_TAG
  end

  test 'a player sees a subsector\'s survey records but not its classified records' do
    subsector = subsectors(:subsector_1_1)
    subsector.update!(player_notes: 'Players know this', referee_notes: 'Referee secret 4471')
    sign_in_as users(:two)
    get api_subsector_url(subsector), as: :json
    assert_response :success
    assert_equal 'Players know this', response.parsed_body['survey_records']
    assert_not response.parsed_body.key?('classified_records')
    assert_not response.parsed_body.key?('classified_records_html')
    assert_not_includes response.body, 'Referee secret 4471'
  end
end
