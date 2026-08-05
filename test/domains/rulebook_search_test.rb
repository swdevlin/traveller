require 'test_helper'

class RulebookSearchTest < ActiveSupport::TestCase
  test 'returns an empty array for a blank query without touching the database' do
    assert_equal [], RulebookSearch.new(query: '', referee: true).call
    assert_equal [], RulebookSearch.new(query: '   ', referee: true).call
  end

  test 'treats blank-string filter values the same as absent filters (e.g. an unselected <select>)' do
    assert_nothing_raised do
      groups = RulebookSearch.new(query: 'jump drive', referee: true, rulebook_ids: [''], editions: [''], categories: ['']).call
      assert_equal 1, groups.size
    end
  end

  test 'minimum_rank filters out hits scoring below the threshold' do
    unfiltered = RulebookSearch.new(query: 'jump drive', referee: true).call
    rank = unfiltered.first.hits.first.rank

    assert_equal 1, RulebookSearch.new(query: 'jump drive', referee: true, minimum_rank: rank - 0.001).call.size
    assert_empty RulebookSearch.new(query: 'jump drive', referee: true, minimum_rank: rank + 0.001).call
  end

  test 'a blank minimum_rank behaves like no filter at all' do
    unfiltered = RulebookSearch.new(query: 'jump drive', referee: true).call
    blank_filter = RulebookSearch.new(query: 'jump drive', referee: true, minimum_rank: '').call

    assert_equal unfiltered.size, blank_filter.size
  end

  test 'finds matches by term, grouped by rulebook' do
    groups = RulebookSearch.new(query: 'jump drive', referee: true).call

    assert_equal 1, groups.size
    group = groups.first
    assert_equal rulebooks(:core).id, group.rulebook.id
    assert_equal 1, group.total_matches
    assert_equal 1, group.hits.size
  end

  test 'excludes rulebooks that are not globally searchable, even when campaign-enabled' do
    rulebooks(:hidden).rulebook_pages.first.update!(normalized_body: 'unique_hidden_term jump drive variants')
    groups = RulebookSearch.new(query: 'unique_hidden_term', referee: true).call

    assert_empty groups
  end

  test 'excludes rulebooks that are not globally ready, even when campaign-enabled' do
    RulebookPage.create!(rulebook: rulebooks(:pending_import), pdf_page_number: 1,
                          normalized_body: 'unique_pending_term appears here')

    groups = RulebookSearch.new(query: 'unique_pending_term', referee: true).call

    assert_empty groups
  end

  test 'excludes a rulebook that has no campaign_rulebooks row at all, even though it is globally ready and searchable' do
    never_enabled = Rulebook.create!(title: 'Never Enabled', category: 'rulebook', status: 'ready',
                                      searchable: true, page_number_offset: 0)
    never_enabled.rulebook_pages.create!(pdf_page_number: 1, normalized_body: 'unique_never_enabled_term appears here')

    assert_empty RulebookSearch.new(query: 'unique_never_enabled_term', referee: true).call
  end

  test 'a referee sees an enabled book even when it is not player-searchable' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)

    assert_equal 1, RulebookSearch.new(query: 'jump drive', referee: true).call.size
  end

  test 'a non-referee (player) does not see an enabled book that is not player-searchable' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)

    assert_empty RulebookSearch.new(query: 'jump drive', referee: false).call
  end

  test 'a non-referee (player) sees a book that is both enabled and player-searchable' do
    campaign_rulebooks(:core_enabled).update!(enabled: true, player_searchable: true)

    assert_equal 1, RulebookSearch.new(query: 'jump drive', referee: false).call.size
  end

  test 'a referee does not see a book that is not enabled for the campaign at all' do
    campaign_rulebooks(:core_enabled).destroy

    assert_empty RulebookSearch.new(query: 'jump drive', referee: true).call
  end

  test 'supports quoted phrase and exclusion syntax' do
    exact_phrase = RulebookSearch.new(query: '"jump drive"', referee: true).call
    assert_equal 1, exact_phrase.size

    excluded = RulebookSearch.new(query: 'jump -trade', referee: true).call
    assert_equal 1, excluded.size
    assert_equal rulebooks(:core).id, excluded.first.rulebook.id

    excluded_everything = RulebookSearch.new(query: 'jump -drive', referee: true).call
    assert_empty excluded_everything
  end

  test 'filters by rulebook_ids' do
    matching = RulebookSearch.new(query: 'jump', referee: true, rulebook_ids: [rulebooks(:core).id]).call
    assert_equal 1, matching.size

    non_matching = RulebookSearch.new(query: 'jump', referee: true, rulebook_ids: [rulebooks(:hidden).id]).call
    assert_empty non_matching
  end

  test 'filters by edition' do
    rulebooks(:core).update!(edition: '2nd')

    assert_equal 1, RulebookSearch.new(query: 'jump', referee: true, editions: ['2nd']).call.size
    assert_empty RulebookSearch.new(query: 'jump', referee: true, editions: ['5th']).call
  end

  test 'filters by category' do
    assert_equal 1, RulebookSearch.new(query: 'jump', referee: true, categories: ['rulebook']).call.size
    assert_empty RulebookSearch.new(query: 'jump', referee: true, categories: ['adventure']).call
  end

  test 'ranks heading matches above ordinary body matches' do
    rulebook = rulebooks(:core)
    heading_page = rulebook.rulebook_pages.create!(pdf_page_number: 50, heading: 'unique_rank_term',
                                                    normalized_body: 'unrelated content')
    body_page = rulebook.rulebook_pages.create!(pdf_page_number: 51, heading: 'Other',
                                                 normalized_body: 'discusses unique_rank_term in passing')

    group = RulebookSearch.new(query: 'unique_rank_term', referee: true, rulebook_ids: [rulebook.id]).call.first

    ranked_ids = group.hits.map { |hit| hit.rulebook_page.pdf_page_number }
    assert_equal [heading_page.pdf_page_number, body_page.pdf_page_number], ranked_ids
  end

  test 'excerpt segments mark matched terms as highlighted and everything else as plain' do
    group = RulebookSearch.new(query: 'jump drive', referee: true).call.first
    segments = group.hits.first.excerpt_segments

    highlighted_texts = segments.select(&:highlighted).map(&:text)
    assert_includes highlighted_texts, 'jump'
    assert_includes highlighted_texts, 'drive'
    assert(segments.any? { |segment| !segment.highlighted })
  end

  test 'heading segments show the page heading, highlighting it when the query matches there' do
    rulebook = rulebooks(:core)
    hit = RulebookSearch.new(query: 'jump drive', referee: true, rulebook_ids: [rulebook.id]).call.first.hits.first
    assert_equal 'Starships', hit.heading_segments.map(&:text).join
    assert(hit.heading_segments.none?(&:highlighted))

    heading_match = RulebookSearch.new(query: 'starships', referee: true, rulebook_ids: [rulebook.id]).call.first.hits.first
    assert_includes heading_match.heading_segments.select(&:highlighted).map(&:text), 'Starships'
  end

  test 'heading segments are empty for a page with no heading' do
    rulebook = rulebooks(:core)
    rulebook.rulebook_pages.create!(pdf_page_number: 70, normalized_body: 'unique_headingless_term appears here')

    hit = RulebookSearch.new(query: 'unique_headingless_term', referee: true, rulebook_ids: [rulebook.id]).call.first.hits.first
    assert_empty hit.heading_segments
  end

  test 'never includes the pdf page number in a hit, only the effective printed page label' do
    group = RulebookSearch.new(query: 'jump drive', referee: true).call.first
    hit = group.hits.first

    assert_not hit.respond_to?(:pdf_page_number)
    assert_equal rulebook_pages(:core_page_starships).effective_printed_page_label, hit.rulebook_page.effective_printed_page_label
  end

  test 'total_matches reflects all matching pages even when hits are capped by per_rulebook_limit' do
    rulebook = rulebooks(:core)
    3.times do |i|
      rulebook.rulebook_pages.create!(pdf_page_number: 60 + i, normalized_body: 'unique_cap_term appears here')
    end

    group = RulebookSearch.new(query: 'unique_cap_term', referee: true, per_rulebook_limit: 1).call.first

    assert_equal 3, group.total_matches
    assert_equal 1, group.hits.size
  end
end
