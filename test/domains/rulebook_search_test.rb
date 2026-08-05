require 'test_helper'

class RulebookSearchTest < ActiveSupport::TestCase
  test 'returns an empty array for a blank query without touching the database' do
    assert_equal [], RulebookSearch.new(query: '', referee: true).call
    assert_equal [], RulebookSearch.new(query: '   ', referee: true).call
  end

  test 'treats blank-string filter values the same as absent filters (e.g. an unselected <select>)' do
    assert_nothing_raised do
      groups = RulebookSearch.new(query: 'jump drive', referee: true, rulebook_ids: [''], categories: ['']).call
      assert_equal 1, groups.size
    end
  end

  test 'MINIMUM_RANK filters out hits scoring below the fixed threshold' do
    rulebook = rulebooks(:core)
    rulebook.rulebook_pages.create!(pdf_page_number: 80,
                                     heading: 'unique_threshold_term unique_threshold_term unique_threshold_term',
                                     normalized_body: 'irrelevant')
    rulebook.rulebook_pages.create!(pdf_page_number: 81, normalized_body: 'unique_threshold_term appears once')

    group = RulebookSearch.new(query: 'unique_threshold_term', referee: true, rulebook_ids: [rulebook.id]).call.first

    assert_equal 1, group.hits.size
    assert_operator group.hits.first.rank, :>=, RulebookSearch::MINIMUM_RANK
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

  test 'filters by category' do
    assert_equal 1, RulebookSearch.new(query: 'jump', referee: true, categories: ['rulebook']).call.size
    assert_empty RulebookSearch.new(query: 'jump', referee: true, categories: ['adventure']).call
  end

  test 'ranks heading matches above ordinary body matches' do
    rulebook = rulebooks(:core)
    # Both pages must individually clear MINIMUM_RANK to appear at all: three heading
    # occurrences (rank 3.0) vs. twelve body-only occurrences (rank 2.4) — comfortably
    # above the 2.0 floor on both sides, while still keeping heading > body.
    heading_page = rulebook.rulebook_pages.create!(pdf_page_number: 50,
                                                    heading: 'unique_rank_term unique_rank_term unique_rank_term',
                                                    normalized_body: 'unrelated content')
    body_page = rulebook.rulebook_pages.create!(pdf_page_number: 51, heading: 'Other',
                                                 normalized_body: (['unique_rank_term'] * 12).join(' ') + ' discussed in passing')

    group = RulebookSearch.new(query: 'unique_rank_term', referee: true, rulebook_ids: [rulebook.id]).call.first

    ranked_ids = group.hits.map { |hit| hit.rulebook_page.pdf_page_number }
    assert_equal [heading_page.pdf_page_number, body_page.pdf_page_number], ranked_ids
  end

  test 'ranks an item/stat-block line above incidental prose repetition' do
    rulebook = rulebooks(:core)
    # Each item-line occurrence contributes item weight 1.2 plus body weight 0.2 (item_lines
    # duplicates rather than removes the line from normalized_body), so 5 occurrences ~= 7.0 —
    # comfortably above MINIMUM_RANK. Each prose-only occurrence contributes body weight 0.2
    # alone, so 11 occurrences (~2.2) also clears the floor but stays well below the item page.
    item_words = (['unique_item_term'] * 5).join(' ')
    item_page = rulebook.rulebook_pages.create!(pdf_page_number: 90, normalized_body: item_words, item_lines: item_words)

    prose_words = 11.times.map { |i| "unique_item_term filler#{i}" }.join(' ')
    prose_page = rulebook.rulebook_pages.create!(pdf_page_number: 91, normalized_body: prose_words)

    group = RulebookSearch.new(query: 'unique_item_term', referee: true, rulebook_ids: [rulebook.id]).call.first

    ranked_ids = group.hits.map { |hit| hit.rulebook_page.pdf_page_number }
    assert_equal [item_page.pdf_page_number, prose_page.pdf_page_number], ranked_ids
  end

  test 'ranks a bold match above incidental prose repetition' do
    rulebook = rulebooks(:core)
    # Same shape as the item-line ranking test above: bold weight 1.0 plus body weight 0.2
    # (bold_text duplicates rather than removes the span from normalized_body), so 5
    # occurrences ~= 6.0 — comfortably above MINIMUM_RANK and above the prose-only page.
    bold_words = (['unique_bold_term'] * 5).join(' ')
    bold_page = rulebook.rulebook_pages.create!(pdf_page_number: 92, normalized_body: bold_words, bold_text: bold_words)

    prose_words = 11.times.map { |i| "unique_bold_term filler#{i}" }.join(' ')
    prose_page = rulebook.rulebook_pages.create!(pdf_page_number: 93, normalized_body: prose_words)

    group = RulebookSearch.new(query: 'unique_bold_term', referee: true, rulebook_ids: [rulebook.id]).call.first

    ranked_ids = group.hits.map { |hit| hit.rulebook_page.pdf_page_number }
    assert_equal [bold_page.pdf_page_number, prose_page.pdf_page_number], ranked_ids
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

    # A single heading occurrence (rank 1.0) sits below MINIMUM_RANK, so the heading is
    # repeated to clear the floor while still exercising heading-match highlighting.
    rulebook.rulebook_pages.create!(pdf_page_number: 71,
                                     heading: 'headingmatchterm headingmatchterm headingmatchterm',
                                     normalized_body: 'unrelated content')
    heading_match = RulebookSearch.new(query: 'headingmatchterm', referee: true, rulebook_ids: [rulebook.id]).call.first.hits.first
    assert_includes heading_match.heading_segments.select(&:highlighted).map(&:text), 'headingmatchterm'
  end

  test 'heading segments are empty for a page with no heading' do
    rulebook = rulebooks(:core)
    # A single body-only occurrence (rank 0.2) sits below MINIMUM_RANK, so the term is
    # repeated with filler between each mention to clear the floor.
    padded_body = 12.times.map { |i| "unique_headingless_term filler#{i}" }.join(' ')
    rulebook.rulebook_pages.create!(pdf_page_number: 70, normalized_body: padded_body)

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
    # A single occurrence (rank 0.2) sits below MINIMUM_RANK, so each page repeats the
    # term, with filler between each mention, to clear the floor.
    3.times do |i|
      padded_body = 12.times.map { |n| "unique_cap_term filler#{n}" }.join(' ')
      rulebook.rulebook_pages.create!(pdf_page_number: 60 + i, normalized_body: padded_body)
    end

    group = RulebookSearch.new(query: 'unique_cap_term', referee: true, per_rulebook_limit: 1).call.first

    assert_equal 3, group.total_matches
    assert_equal 1, group.hits.size
  end
end
