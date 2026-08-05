require 'test_helper'

class RulebookTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert rulebooks(:core).valid?
  end

  test 'requires a title' do
    rulebook = Rulebook.new(category: 'rulebook')
    assert_not rulebook.valid?
    assert_includes rulebook.errors[:title], "can't be blank"
  end

  test 'rejects an unknown status' do
    rulebook = Rulebook.new(title: 'x', category: 'rulebook', status: 'nonsense')
    assert_not rulebook.valid?
    assert_includes rulebook.errors[:status], 'is not included in the list'
  end

  test 'rejects an unknown category' do
    rulebook = Rulebook.new(title: 'x', category: 'nonsense')
    assert_not rulebook.valid?
    assert_includes rulebook.errors[:category], 'is not included in the list'
  end

  test 'accepts a valid header/footer regular expression pattern' do
    rulebook = rulebooks(:core)
    rulebook.header_footer_patterns = ['Traveller Core Rulebook \\d+']
    assert rulebook.valid?
  end

  test 'rejects an invalid header/footer regular expression pattern' do
    rulebook = rulebooks(:core)
    rulebook.header_footer_patterns = ['(unterminated']
    assert_not rulebook.valid?
    assert_includes rulebook.errors[:header_footer_patterns].join, '(unterminated'
  end

  test 'searchable scope only includes ready, searchable rulebooks' do
    assert_includes Rulebook.searchable, rulebooks(:core)
    assert_not_includes Rulebook.searchable, rulebooks(:hidden)
    assert_not_includes Rulebook.searchable, rulebooks(:failed_import)
    assert_not_includes Rulebook.searchable, rulebooks(:pending_import)
  end

  test 'to_s prefers short_title over title' do
    assert_equal 'Core', rulebooks(:core).to_s
  end

  test 'to_s falls back to title when short_title is blank' do
    rulebook = rulebooks(:core)
    rulebook.short_title = nil
    assert_equal 'Core Rulebook', rulebook.to_s
  end

  test 'destroying a rulebook destroys its pages' do
    rulebook = rulebooks(:core)
    page_ids = rulebook.rulebook_pages.pluck(:id)
    assert page_ids.any?

    rulebook.destroy!

    assert_empty RulebookPage.where(id: page_ids)
  end
end
