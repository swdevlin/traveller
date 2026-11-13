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

  test 'counts repeated page views individually' do
    visit = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, user: users(:one), started_at: 1.day.ago)
    3.times do
      Ahoy::Event.create!(visit: visit, name: 'Viewed page', time: 1.day.ago,
                           properties: { campaign_id: @campaign.id })
    end

    sign_in_as users(:admin)
    get admin_root_url

    assert_response :success
    assert_select 'td.text-right', text: '3', count: 1
  end

  test 'counts starmap users distinctly, not starmap loads or page views' do
    signed_in = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid,
                                    user: users(:one), started_at: 1.day.ago)
    2.times do
      Ahoy::Event.create!(visit: signed_in, name: 'Used starmap', time: 1.day.ago,
                           properties: { campaign_id: @campaign.id })
    end

    2.times do
      anonymous = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid,
                                      started_at: 1.day.ago)
      Ahoy::Event.create!(visit: anonymous, name: 'Used starmap', time: 1.day.ago,
                           properties: { campaign_id: @campaign.id })
    end

    sign_in_as users(:admin)
    get admin_root_url

    assert_response :success
    # Three people (one signed in, two anonymous browsers), and no page views.
    assert_select 'td.text-right', text: '3', count: 1
  end

  test 'counts rule search views, searches and result views separately per campaign' do
    visit = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, started_at: 1.day.ago)
    2.times do
      Ahoy::Event.create!(visit: visit, name: 'Viewed rule search', time: 1.day.ago,
                           properties: { campaign_id: @campaign.id })
    end
    5.times do
      Ahoy::Event.create!(visit: visit, name: 'Searched rules', time: 1.day.ago,
                           properties: { campaign_id: @campaign.id, result_count: 4, source: 'web' })
    end
    3.times do
      Ahoy::Event.create!(visit: visit, name: 'Expanded rule results', time: 1.day.ago,
                           properties: { campaign_id: @campaign.id, rulebook_id: 1 })
    end
    Ahoy::Event.create!(visit: visit, name: 'Searched rules', time: 2.weeks.ago,
                         properties: { campaign_id: @campaign.id })

    sign_in_as users(:admin)
    get admin_root_url

    assert_response :success
    assert_select 'td.text-right', text: '2 / 5 / 3', count: 1
  end

  test 'shows referee and player page view counts for the last week' do
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
