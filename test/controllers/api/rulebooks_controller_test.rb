require 'test_helper'

class Api::RulebooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @rulebook = campaign_rulebooks(:core_enabled).rulebook
  end

  test 'lists an enabled, player-searchable rulebook for an anonymous caller' do
    get api_rulebooks_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success
    entry = response.parsed_body.find { |r| r['id'] == @rulebook.id }
    assert_equal @rulebook.title, entry['title']
    assert_equal @rulebook.category, entry['category']
  end

  test 'hides a book that is not player searchable from players' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)
    get api_rulebooks_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success
    assert_not_includes response.parsed_body.map { |r| r['id'] }, @rulebook.id
  end

  test 'shows the owner every enabled book' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)
    sign_in_as @campaign.referee
    get api_rulebooks_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success
    assert_includes response.parsed_body.map { |r| r['id'] }, @rulebook.id
  end

  test 'never lists a book the campaign has not enabled' do
    campaign_rulebooks(:core_enabled).destroy
    sign_in_as @campaign.referee
    get api_rulebooks_url(campaign_slug: @campaign.slug), as: :json
    assert_not_includes response.parsed_body.map { |r| r['id'] }, @rulebook.id
  end
end
