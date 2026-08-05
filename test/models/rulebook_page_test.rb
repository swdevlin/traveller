require 'test_helper'

class RulebookPageTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert rulebook_pages(:core_page_starships).valid?
  end

  test 'requires a pdf_page_number' do
    page = RulebookPage.new(rulebook: rulebooks(:core))
    assert_not page.valid?
    assert_includes page.errors[:pdf_page_number], "can't be blank"
  end

  test 'pdf_page_number is unique per rulebook' do
    duplicate = RulebookPage.new(rulebook: rulebooks(:core), pdf_page_number: 1)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:pdf_page_number], 'has already been taken'
  end

  test 'the same pdf_page_number is allowed across different rulebooks' do
    # rulebooks(:core) already has a page at pdf_page_number 2 (core_page_trade);
    # rulebooks(:hidden) does not, so this must be allowed.
    page = RulebookPage.new(rulebook: rulebooks(:hidden), pdf_page_number: 2)
    page.valid?
    assert_not_includes page.errors[:pdf_page_number], 'has already been taken'
  end

  test 'rejects setting both an override and unnumbered' do
    page = rulebook_pages(:core_page_starships)
    page.printed_page_number_override = 5
    page.printed_page_unnumbered = true

    assert_not page.valid?
    assert_includes page.errors[:base], 'cannot both override the printed page number and mark it unnumbered'
  end

  test 'the database check constraint enforces the same rule independently of model validation' do
    page = rulebook_pages(:core_page_starships)

    assert_raises(ActiveRecord::StatementInvalid) do
      page.update_columns(printed_page_number_override: 5, printed_page_unnumbered: true)
    end
  end

  test 'effective_printed_page_number uses the offset when there is no override' do
    page = rulebook_pages(:core_page_starships)
    # rulebooks(:core) has page_number_offset: -2, pdf_page_number: 1
    # offset is (pdf page - printed page), so printed page = pdf page - offset = 1 - (-2) = 3
    assert_equal 3, page.effective_printed_page_number
  end

  test 'effective_printed_page_number prefers an explicit override' do
    page = rulebook_pages(:core_page_trade)
    assert_equal 99, page.effective_printed_page_number
  end

  test 'effective_printed_page_number is nil when marked unnumbered' do
    page = rulebook_pages(:core_page_cover)
    assert_nil page.effective_printed_page_number
  end

  test 'effective_printed_page_label shows the numeric page when numbered' do
    assert_equal '99', rulebook_pages(:core_page_trade).effective_printed_page_label
  end

  test 'effective_printed_page_label shows a fallback string when unnumbered' do
    assert_equal 'Unnumbered page', rulebook_pages(:core_page_cover).effective_printed_page_label
  end
end
