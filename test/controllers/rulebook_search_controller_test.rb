require 'test_helper'

class RulebookSearchControllerTest < ActionDispatch::IntegrationTest
  # Ahoy skips bot-looking user agents, which includes the Rails test client's default.
  BROWSER_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 ' \
                       '(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36'

  setup do
    self.default_url_options = { campaign_slug: campaigns(:one).slug }
  end

  test 'renders for a fully logged-out request' do
    get rulebook_search_url, params: { q: 'jump drive' }
    assert_response :success
    assert_includes @response.body, 'jump'
  end

  test 'renders for a user logged in as a different campaign\'s referee the same as logged-out' do
    # referee? checks Current.owns_campaign?, which is false here since
    # users(:two) is not campaigns(:one)'s own referee — so this behaves
    # exactly like an anonymous player, not like campaigns(:one)'s own referee.
    sign_in_as users(:two)
    get rulebook_search_url, params: { q: 'jump drive' }
    assert_response :success
  end

  test 'a user logged in as a different campaign\'s referee does not see an enabled book that is not player-searchable' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)
    sign_in_as users(:two)

    get rulebook_search_url, params: { q: 'jump drive' }
    assert_response :success
    assert_includes @response.body, 'No matches'
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

  test 'opening the search page tracks a view, not a search' do
    assert_difference -> { Ahoy::Event.where(name: 'Viewed rule search').count }, 1 do
      assert_no_difference -> { Ahoy::Event.where(name: 'Searched rules').count } do
        get rulebook_search_url, headers: { 'User-Agent' => BROWSER_USER_AGENT }
      end
    end
    assert_equal campaigns(:one).id, Ahoy::Event.where(name: 'Viewed rule search').last.properties['campaign_id']
  end

  test 'running a search tracks a search with campaign and result count, not a view' do
    assert_difference -> { Ahoy::Event.where(name: 'Searched rules').count }, 1 do
      assert_no_difference -> { Ahoy::Event.where(name: 'Viewed rule search').count } do
        get rulebook_search_url, params: { q: 'jump drive' }, headers: { 'User-Agent' => BROWSER_USER_AGENT }
      end
    end
    properties = Ahoy::Event.where(name: 'Searched rules').last.properties
    assert_equal campaigns(:one).id, properties['campaign_id']
    assert_equal 'web', properties['source']
    assert_kind_of Integer, properties['result_count']
    assert_not_includes properties.keys, 'query'
  end

  test 'expanding a rulebook\'s results tracks an expansion, not a search or view' do
    rulebook = campaign_rulebooks(:core_enabled).rulebook

    assert_difference -> { Ahoy::Event.where(name: 'Expanded rule results').count }, 1 do
      assert_no_difference -> { Ahoy::Event.where(name: ['Searched rules', 'Viewed rule search']).count } do
        get more_rulebook_search_url, params: { q: 'jump drive', rulebook_id: rulebook.id },
                                      headers: { 'User-Agent' => BROWSER_USER_AGENT }
      end
    end
    properties = Ahoy::Event.where(name: 'Expanded rule results').last.properties
    assert_equal campaigns(:one).id, properties['campaign_id']
    assert_equal rulebook.id, properties['rulebook_id']
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

  test 'a request with a valid campaign bearer token sees an enabled book that is not player-searchable' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)

    get rulebook_search_url,
        params: { q: 'jump drive' },
        headers: { 'Authorization' => "Bearer #{campaigns(:one).api_token}" }

    assert_response :success
    assert_not_includes @response.body, 'No matches'
  end

  test 'a request with an invalid bearer token behaves like an anonymous player' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)

    get rulebook_search_url,
        params: { q: 'jump drive' },
        headers: { 'Authorization' => 'Bearer not-the-real-token' }

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

  test 'JSON response includes relevant_matches and low_relevance_hits alongside the existing fields' do
    get rulebook_search_url(format: :json), params: { q: 'jump drive' }
    assert_response :success

    body = JSON.parse(@response.body)
    group = body.first
    assert group.key?('relevant_matches')
    assert_kind_of Integer, group['relevant_matches']
    assert group.key?('low_relevance_hits')
    assert_kind_of Array, group['low_relevance_hits']
  end

  test 'filters by category via the api endpoint' do
    get api_rulebook_search_url, params: { q: 'jump', categories: 'adventure' }
    body = JSON.parse(@response.body)
    assert_empty body
  end
end
