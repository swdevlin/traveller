require 'test_helper'

# Exercises the real PyMuPDF4LLM-backed libexec/extract_rulebook.py against a small
# fixture PDF. Deliberately asserts only on structural properties (page count, presence
# of a known substring per page) rather than exact extracted text, since the library's
# exact markdown formatting can vary across versions.
class PdfTextExtractorTest < ActiveSupport::TestCase
  setup do
    @path = file_fixture('sample_rulebook.pdf')
    @extractor = PdfTextExtractor.new
  end

  test 'extract returns one page per PDF page, in order' do
    result = @extractor.extract(@path)

    assert_equal 3, result.page_count
    assert_equal [1, 2, 3], result.pages.map(&:page_number)
  end

  test 'extract returns the text of each page, in reading order' do
    result = @extractor.extract(@path)

    first_page = result.pages.first.text
    assert_includes first_page, 'jump drive'
    assert_not_includes first_page, 'Trade and Commerce'
  end

  test 'extract returns different text for different pages' do
    result = @extractor.extract(@path)

    assert_not_equal result.pages[0].text, result.pages[1].text
  end

  test 'extract raises ExtractionError for a nonexistent file' do
    assert_raises(PdfTextExtractor::ExtractionError) do
      @extractor.extract(Rails.root.join('tmp/does_not_exist.pdf'))
    end
  end

  test 'extract raises ExtractionError for a path that is not a regular file' do
    assert_raises(PdfTextExtractor::ExtractionError) do
      @extractor.extract(Rails.root.join('tmp'))
    end
  end
end
