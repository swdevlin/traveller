require 'test_helper'

class RulebookSearchFlowTest < ActionDispatch::IntegrationTest
  setup do
    self.default_url_options = { campaign_slug: campaigns(:one).slug }
  end

  # Matches only text actually wrapped in a highlighted <mark>, so it isn't
  # confused by the search term also appearing in the input's `value=` attribute
  # or the "show more" turbo-frame's `src=` URL.
  def highlighted_occurrences(term)
    @response.body.scan(%r{<mark[^>]*>#{term}</mark>}).size
  end

  # A single occurrence of a term scores well below RulebookSearch::MINIMUM_RANK, so
  # fixtures that need to clear the fixed floor repeat the term — spread apart with
  # filler words so ts_headline's MaxFragments=1 excerpt still only ever highlights one
  # occurrence, keeping highlighted_occurrences assertions meaningful.
  def padded_match_body(term, occurrences: 12)
    occurrences.times.map { |i| "#{term} #{(1..40).map { |n| "filler#{i}_#{n}" }.join(' ')}" }.join(' . ')
  end

  test 'searching renders results, and the show-more frame reveals additional hits beyond the initial page' do
    rulebook = rulebooks(:core)
    4.upto(7) do |n|
      rulebook.rulebook_pages.create!(pdf_page_number: n, normalized_body: padded_match_body('wibblewobble'))
    end

    get rulebook_search_url, params: { q: 'wibblewobble' }
    assert_response :success
    # Only the first RESULTS_PER_RULEBOOK (3) of the 4 matching hits are shown inline;
    # the rest are behind the lazy-loaded "show more" turbo-frame.
    assert_equal 3, highlighted_occurrences('wibblewobble')
    assert_includes @response.body, "rulebook-#{rulebook.id}-more"

    get more_rulebook_search_url, params: { rulebook_id: rulebook.id, q: 'wibblewobble' }
    assert_response :success
    assert_equal 1, highlighted_occurrences('wibblewobble')
  end

  test 'the relevant/low-relevance split is applied consistently on the initial page and the lazy-loaded "show more" frame' do
    rulebook = rulebooks(:core)
    # Well above RELEVANT_RANK_THRESHOLD (rank 3.0): heading match repeated three times.
    5.times { |i| rulebook.rulebook_pages.create!(pdf_page_number: 10 + i, heading: 'distincttestterm distincttestterm distincttestterm', normalized_body: 'irrelevant') }
    # Above MINIMUM_RANK but below RELEVANT_RANK_THRESHOLD (rank 0.2): a single body-only mention.
    2.times { |i| rulebook.rulebook_pages.create!(pdf_page_number: 20 + i, normalized_body: 'distincttestterm appears once') }

    get rulebook_search_url, params: { q: 'distincttestterm' }
    assert_response :success
    # RESULTS_PER_RULEBOOK (3) of the 5 relevant heading hits, plus both low-relevance
    # body hits (only 2 exist, under the same per-bucket cap) — both buckets render
    # server-side; the low-relevance ones are CSS-hidden by default.
    assert_equal 5, @response.body.scan(/rank \d+\.\d+/).size
    assert_equal 2, @response.body.scan('data-low-relevance-hit').size
    assert_includes @response.body, "rulebook-#{rulebook.id}-more"

    get more_rulebook_search_url, params: { rulebook_id: rulebook.id, q: 'distincttestterm' }
    assert_response :success
    rendered_ranks = @response.body.scan(/rank ([\d.]+)/).flatten.map(&:to_f)
    # The remaining 2 of the 5 qualifying relevant heading hits — the 2 low-relevance
    # body-only hits were already fully shown inline, so "more" adds nothing for them.
    assert_equal 2, rendered_ranks.size
    assert rendered_ranks.all? { |r| r >= RulebookSearch::RELEVANT_RANK_THRESHOLD },
           "expected all 'more' ranks >= #{RulebookSearch::RELEVANT_RANK_THRESHOLD}, got #{rendered_ranks}"
  end

  test 'an unauthenticated player can search, then the referee can hide a rulebook from the campaign entirely' do
    get rulebook_search_url, params: { q: 'jump drive' }
    assert_includes @response.body, 'Core Rulebook'

    sign_in_as users(:one)
    patch toggle_enabled_library_url(rulebook_id: rulebooks(:core).id)
    sign_out

    get rulebook_search_url, params: { q: 'jump drive' }
    assert_includes @response.body, 'No matches'
  end

  test 'the referee enables a rulebook via the Library page, then a player can search it' do
    campaign_rulebooks(:core_enabled).destroy

    get rulebook_search_url, params: { q: 'jump drive' }
    assert_includes @response.body, 'No matches'

    sign_in_as users(:one)
    get library_url
    assert_response :success
    assert_includes @response.body, 'Core Rulebook'

    patch toggle_enabled_library_url(rulebook_id: rulebooks(:core).id)
    patch toggle_player_searchable_library_url(rulebook_id: rulebooks(:core).id)
    sign_out

    get rulebook_search_url, params: { q: 'jump drive' }
    assert_includes @response.body, 'Core Rulebook'
  end

  test 'a non-referee cannot reach the Library page for someone else\'s campaign' do
    sign_in_as users(:two)
    get library_url
    assert_response :redirect
  end
end
