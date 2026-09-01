require 'test_helper'

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  test 'a logged-out request is 404, not a redirect' do
    get admin_root_url
    assert_response :not_found
  end

  test 'a logged-in, non-admin request is 404' do
    sign_in_as users(:one)
    get admin_root_url
    assert_response :not_found
  end

  test 'an admin can view the dashboard' do
    sign_in_as users(:admin)
    get admin_root_url
    assert_response :success
  end

  test 'shows referee and player visit counts for the last week' do
    referee_visit = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, user: users(:one), started_at: 1.day.ago)
    Ahoy::Event.create!(visit: referee_visit, name: 'Viewed page', time: 1.day.ago,
                         properties: { campaign_id: @campaign.id })

    player_visit = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, started_at: 1.day.ago)
    Ahoy::Event.create!(visit: player_visit, name: 'Viewed page', time: 1.day.ago,
                         properties: { campaign_id: @campaign.id })

    stale_visit = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, user: users(:one), started_at: 2.weeks.ago)
    Ahoy::Event.create!(visit: stale_visit, name: 'Viewed page', time: 2.weeks.ago,
                         properties: { campaign_id: @campaign.id })

    sign_in_as users(:admin)
    get admin_root_url

    assert_response :success
    assert_select 'td.text-right', text: '1', count: 2
  end
end
