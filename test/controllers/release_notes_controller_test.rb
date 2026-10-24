require 'test_helper'

class ReleaseNotesControllerTest < ActionDispatch::IntegrationTest
  test 'deltas page is available without logging in' do
    get '/deltas'
    assert_response :success
  end

  test 'deltas page links to the rss feed' do
    get '/deltas'
    assert_select "button[data-clipboard-url-value$='/deltas/feed']"
    assert_select "link[type='application/rss+xml']"
  end

  test 'feed is valid rss without logging in' do
    get '/deltas/feed'
    assert_response :success
    assert_equal 'application/rss+xml', response.media_type
    rss = RSS::Parser.parse(response.body)
    assert_equal 'My Traveller Universe Deltas', rss.channel.title
    assert_predicate rss.items, :any?
  end

  test 'feed urls ignore the campaign slug' do
    get "/deltas?campaign_slug=#{campaigns(:one).slug}"
    assert_response :success
    assert_select "button[data-clipboard-url-value$='/deltas/feed']"
    assert_select "link[href*='campaign_slug']", false

    get '/deltas/feed', params: { campaign_slug: campaigns(:one).slug }
    assert_not_includes response.body, 'campaign_slug'
  end
end
