require 'test_helper'

class AhoyTrackingTest < ActionDispatch::IntegrationTest
  # Ahoy excludes bot-looking user agents (Ahoy.track_bots is false), and the
  # Rails test client's default User-Agent gets classified as a bot, which
  # would silently skip tracking entirely.
  BROWSER_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                        '(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'

  setup do
    @campaign = campaigns(:one)
    self.default_url_options = { campaign_slug: @campaign.slug }
  end

  test 'a visit that started before sign-in is attributed to the user on their next request' do
    get rulebook_search_url, params: { q: 'jump drive' }, headers: { 'User-Agent' => BROWSER_USER_AGENT }
    assert_response :success

    visit = Ahoy::Visit.order(:started_at).last
    assert_nil visit.user_id

    sign_in_as users(:one)
    get rulebook_search_url, params: { q: 'jump drive' }, headers: { 'User-Agent' => BROWSER_USER_AGENT }
    assert_response :success

    assert_equal users(:one).id, visit.reload.user_id
  end
end
