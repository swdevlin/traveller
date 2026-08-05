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

  test 'searching renders results, and the show-more frame reveals additional hits beyond the initial page' do
    rulebook = rulebooks(:core)
    4.upto(7) do |n|
      rulebook.rulebook_pages.create!(pdf_page_number: n, normalized_body: 'wibblewobble appears on this page')
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

  test 'minimum_rank is respected by the lazy-loaded "show more" frame, not just the initial page' do
    rulebook = rulebooks(:core)
    # Heading matches (tsvector weight A) rank higher than body-only matches (weight B).
    5.times { |i| rulebook.rulebook_pages.create!(pdf_page_number: 10 + i, heading: 'distincttestterm', normalized_body: 'irrelevant') }
    2.times { |i| rulebook.rulebook_pages.create!(pdf_page_number: 20 + i, normalized_body: 'distincttestterm appears once') }

    unfiltered = RulebookSearch.new(query: 'distincttestterm', referee: true, rulebook_ids: [rulebook.id]).call.first
    ranks = unfiltered.hits.map(&:rank).sort
    # A threshold strictly between the low body-only ranks and the high heading ranks:
    # keeps the 5 heading hits, excludes the 2 body-only hits.
    threshold = (ranks[1] + ranks[2]) / 2.0

    get rulebook_search_url, params: { q: 'distincttestterm', minimum_rank: threshold }
    assert_response :success
    assert_includes @response.body, "rulebook-#{rulebook.id}-more"

    get more_rulebook_search_url, params: { rulebook_id: rulebook.id, q: 'distincttestterm', minimum_rank: threshold }
    assert_response :success
    rendered_ranks = @response.body.scan(/rank ([\d.]+)/).flatten.map(&:to_f)
    assert rendered_ranks.present?
    assert rendered_ranks.all? { |r| r >= threshold }, "expected all rendered ranks >= #{threshold}, got #{rendered_ranks}"
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
