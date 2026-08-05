require 'test_helper'

class RulebookReindexerTest < ActiveSupport::TestCase
  test 'renormalizes every page using the current header/footer patterns without touching body' do
    rulebook = rulebooks(:core)
    rulebook.update!(header_footer_patterns: ['CORE RULEBOOK'])
    page = rulebook_pages(:core_page_starships)
    original_body = page.body

    RulebookReindexer.new(rulebook).call

    page.reload
    assert_equal original_body, page.body
    assert_not_includes page.normalized_body, 'CORE RULEBOOK'
    assert_includes page.normalized_body, 'jump'
  end

  test 'recomputes the generated search_vector after renormalizing' do
    rulebook = rulebooks(:core)
    page = rulebook_pages(:core_page_starships)
    assert_includes page.search_vector.to_s, 'consum'

    # Strips a body phrase (not the heading, which the reindexer never touches) so
    # only the normalized_body-derived half of the generated tsvector should change.
    rulebook.update!(header_footer_patterns: ['consumes fuel proportional to jump distance and hull tonnage\\.'])

    RulebookReindexer.new(rulebook).call

    page.reload
    assert_not_includes page.search_vector.to_s, 'consum'
    assert_includes page.search_vector.to_s, 'starship' # heading term is unaffected
  end

  test 'populates heading from a markdown heading line in the stored raw body' do
    rulebook = rulebooks(:core)
    page = rulebook_pages(:core_page_starships)
    page.update!(body: "# Discovered Heading\n\nSome body text.", heading: nil)

    RulebookReindexer.new(rulebook).call

    assert_equal 'Discovered Heading', page.reload.heading
  end

  test 'never nulls out an existing heading when the stored raw body has no markdown heading' do
    rulebook = rulebooks(:core)
    page = rulebook_pages(:core_page_starships)
    assert_equal 'Starships', page.heading

    RulebookReindexer.new(rulebook).call

    assert_equal 'Starships', page.reload.heading
  end

  test 'only touches pages belonging to the given rulebook' do
    other_page = rulebook_pages(:hidden_page_one)
    original_normalized = other_page.normalized_body

    RulebookReindexer.new(rulebooks(:core)).call

    assert_equal original_normalized, other_page.reload.normalized_body
  end
end
