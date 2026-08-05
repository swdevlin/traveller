require 'test_helper'

class RulebookSearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    self.default_url_options = { campaign_slug: campaigns(:one).slug }
  end

  test 'renders for a fully logged-out request' do
    get rulebook_search_url, params: { q: 'jump drive' }
    assert_response :success
    assert_includes @response.body, 'jump'
  end

  test 'renders for a user logged in as a different campaign\'s referee the same as logged-out' do
    # find_session_by_cookie refuses to resume this session for campaigns(:one),
    # since users(:two) is not campaigns(:one)'s own referee — so this behaves
    # exactly like an anonymous player, not like campaigns(:one)'s own referee.
    sign_in_as users(:two)
    get rulebook_search_url, params: { q: 'jump drive' }
    assert_response :success
  end

  test 'sets a noindex meta tag' do
    get rulebook_search_url, params: { q: 'jump drive' }
    assert_includes @response.body, 'name="robots" content="noindex"'
  end

  test 'shows the empty-state guidance for a blank query, not an error' do
    get rulebook_search_url
    assert_response :success
    assert_includes @response.body, 'Enter a search term'
  end

  test 'shows the no-results state for a query with zero matches' do
    get rulebook_search_url, params: { q: 'zzz_no_such_term_zzz' }
    assert_response :success
    assert_includes @response.body, 'No matches'
  end

  test 'handles a malformed query safely' do
    get rulebook_search_url, params: { q: '"unterminated phrase' }
    assert_response :success
  end

  test 'a rulebook disabled for this campaign never appears, even logged out' do
    campaign_rulebooks(:core_enabled).destroy

    get rulebook_search_url, params: { q: 'jump drive' }
    assert_response :success
    assert_includes @response.body, 'No matches'
  end

  test 'the campaign\'s own referee sees an enabled book that is not player-searchable' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)
    sign_in_as users(:one)

    get rulebook_search_url, params: { q: 'jump drive' }
    assert_response :success
    assert_not_includes @response.body, 'No matches'
  end

  test 'an anonymous player does not see an enabled book that is not player-searchable' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)

    get rulebook_search_url, params: { q: 'jump drive' }
    assert_response :success
    assert_includes @response.body, 'No matches'
  end

  test 'JSON response includes every key even when short_title/edition are absent' do
    rulebooks(:core).update!(short_title: nil, edition: nil)

    get rulebook_search_url(format: :json), params: { q: 'jump drive' }
    assert_response :success

    body = JSON.parse(@response.body)
    group = body.first
    assert group.key?('short_title')
    assert_nil group['short_title']
    assert group.key?('edition')
    assert_nil group['edition']
  end

  test 'JSON response never includes the PDF page number' do
    get rulebook_search_url(format: :json), params: { q: 'jump drive' }
    assert_response :success

    assert_not @response.body.include?('pdf_page_number')
  end

  test 'JSON response never includes full page body text, only a short excerpt' do
    get rulebook_search_url(format: :json), params: { q: 'jump drive' }
    body = JSON.parse(@response.body)
    excerpt_text = body.first['hits'].first['excerpt_segments'].map { |s| s['text'] }.join

    assert_operator excerpt_text.length, :<, rulebook_pages(:core_page_starships).body.length
  end

  test 'filters by category via the api endpoint' do
    get api_rulebook_search_url, params: { q: 'jump', categories: 'adventure' }
    body = JSON.parse(@response.body)
    assert_empty body
  end
end
