require 'test_helper'

class Admin::MetricsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @visit = Ahoy::Visit.create!(visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid, started_at: 1.day.ago)
  end

  def track(name, time: 1.day.ago, visit: @visit, **properties)
    Ahoy::Event.create!(visit: visit, name: name, time: time, properties: { campaign_id: @campaign.id }.merge(properties))
  end

  test 'a logged-out request is 404' do
    get admin_metrics_url
    assert_response :not_found
  end

  test 'a non-admin request is 404' do
    sign_in_as users(:one)
    get admin_metrics_url
    assert_response :not_found
  end

  test 'counts handouts and distinct systems per campaign' do
    3.times { |i| track('Generated handout', star_system_id: i.zero? ? 1 : 2) }

    sign_in_as users(:admin)
    get admin_metrics_url

    assert_response :success
    assert_select 'tbody td.text-right', text: '3', count: 1
    assert_select 'tbody td.text-right', text: '2', count: 1
    assert_select 'tfoot td.text-right', text: '3', count: 1
    assert_select 'tfoot td.text-right', text: '2', count: 1
  end

  test 'counts rule lookup views, searches and results separately' do
    2.times { track('Viewed rule search') }
    5.times { track('Searched rules') }
    3.times { track('Expanded rule results') }

    sign_in_as users(:admin)
    get admin_metrics_url

    assert_response :success
    %w[2 5 3].each { |count| assert_select 'tbody td.text-right', text: count, count: 1 }
  end

  test 'counts starmap users distinctly' do
    2.times { track('Used starmap') }
    2.times do
      track('Used starmap', visit: Ahoy::Visit.create!(visit_token: SecureRandom.uuid, visitor_token: SecureRandom.uuid,
                                                         started_at: 1.day.ago))
    end

    sign_in_as users(:admin)
    get admin_metrics_url

    assert_select 'tbody td.text-right', text: '3', count: 1
  end

  test 'the window limits the counts' do
    track('Generated handout', star_system_id: 1)
    track('Generated handout', time: 20.days.ago, star_system_id: 2)
    track('Generated handout', time: 60.days.ago, star_system_id: 3)

    sign_in_as users(:admin)

    get admin_metrics_url(window: '7d')
    assert_select 'tbody td.text-right', text: '1', count: 2

    get admin_metrics_url
    assert_select 'tbody td.text-right', text: '2', count: 2

    get admin_metrics_url(window: 'all')
    assert_select 'tbody td.text-right', text: '3', count: 2
  end

  test 'shows each section table with a zero total row when there is no activity' do
    sign_in_as users(:admin)
    get admin_metrics_url

    assert_response :success
    assert_select 'table', count: FeatureUsage::Catalogue.all.size
    assert_select 'tfoot th', text: 'Total', count: FeatureUsage::Catalogue.all.size
    assert_select 'tbody td', text: 'No activity in this period.', count: FeatureUsage::Catalogue.all.size
  end

  test 'an unknown window falls back to the default' do
    sign_in_as users(:admin)
    get admin_metrics_url(window: 'bogus')
    assert_response :success
  end
end
