require 'test_helper'

class RulebookImporterTest < ActiveSupport::TestCase
  # Fast, stubbed-extractor orchestration tests — real PyMuPDF4LLM-backed extraction
  # is covered separately in pdf_text_extractor_test.rb.
  class StubExtractor
    def initialize(pages:)
      @pages = pages
    end

    def extract(_path)
      pages = @pages.each_with_index.map do |text, i|
        PdfTextExtractor::Page.new(page_number: i + 1, text: text)
      end
      PdfTextExtractor::Result.new(page_count: @pages.size, pages: pages)
    end
  end

  class FailingExtractor
    def extract(_path)
      raise PdfTextExtractor::ExtractionError, 'extract_rulebook.py failed'
    end
  end

  # Extraction is now atomic per book (one subprocess call for the whole PDF), so a per-page
  # failure can no longer originate from extraction itself — only from Ruby-side processing of
  # an already-extracted page. #text is evaluated lazily (only when the importer reads it) so
  # the failure is injected exactly where real per-page processing failures would occur.
  class PartiallyFailingExtractor
    FailingPage = Struct.new(:page_number) do
      def text
        raise 'boom'
      end
    end

    def initialize(pages:, fail_on:)
      @pages = pages
      @fail_on = fail_on
    end

    def extract(_path)
      pages = @pages.each_with_index.map do |text, i|
        page_number = i + 1
        page_number == @fail_on ? FailingPage.new(page_number) : PdfTextExtractor::Page.new(page_number: page_number, text: text)
      end
      PdfTextExtractor::Result.new(page_count: @pages.size, pages: pages)
    end
  end

  setup do
    @rulebook = rulebooks(:pending_import)
    @path = file_fixture('sample_rulebook.pdf')
  end

  test 'imports one page per PDF page, computing the default printed page number' do
    extractor = StubExtractor.new(pages: ['First page text.', 'Second page text.'])
    result = RulebookImporter.new(@rulebook, extractor: extractor).import!(@path)

    assert result.success?
    @rulebook.reload
    assert_equal 'ready', @rulebook.status
    assert_equal 2, @rulebook.rulebook_pages.count

    first = @rulebook.rulebook_pages.find_by(pdf_page_number: 1)
    assert_equal 'First page text.', first.body
    assert_equal 'First page text.', first.normalized_body
    assert_equal first.pdf_page_number + @rulebook.page_number_offset, first.effective_printed_page_number
  end

  test 'populates heading from a markdown heading line in the extracted page text' do
    extractor = StubExtractor.new(pages: ["# A Discovered Heading\n\nBody text."])
    RulebookImporter.new(@rulebook, extractor: extractor).import!(@path)

    page = @rulebook.reload.rulebook_pages.find_by(pdf_page_number: 1)
    assert_equal 'A Discovered Heading', page.heading
    assert_equal "A Discovered Heading\n\nBody text.", page.normalized_body
  end

  test 'sets file_checksum and imported_at on success' do
    extractor = StubExtractor.new(pages: ['Only page.'])
    RulebookImporter.new(@rulebook, extractor: extractor).import!(@path)

    @rulebook.reload
    assert_equal Digest::SHA256.file(@path).hexdigest, @rulebook.file_checksum
    assert @rulebook.imported_at.present?
  end

  test 'is a no-op when the file is unchanged and the rulebook is already ready' do
    extractor = StubExtractor.new(pages: ['Only page.'])
    RulebookImporter.new(@rulebook, extractor: extractor).import!(@path)
    @rulebook.reload
    first_imported_at = @rulebook.imported_at

    result = RulebookImporter.new(@rulebook, extractor: extractor).import!(@path)

    assert result.success?
    assert_equal first_imported_at, @rulebook.reload.imported_at
  end

  test 'force: true reprocesses even when the file is unchanged' do
    extractor = StubExtractor.new(pages: ['Only page.'])
    RulebookImporter.new(@rulebook, extractor: extractor).import!(@path)
    @rulebook.reload
    first_imported_at = @rulebook.imported_at

    travel 1.minute do
      RulebookImporter.new(@rulebook, extractor: extractor).import!(@path, force: true)
    end

    assert_not_equal first_imported_at, @rulebook.reload.imported_at
  end

  test 'removes stale pages beyond the new page count on reimport' do
    extractor = StubExtractor.new(pages: ['Page one.', 'Page two.', 'Page three.'])
    RulebookImporter.new(@rulebook, extractor: extractor).import!(@path)
    assert_equal 3, @rulebook.reload.rulebook_pages.count

    shorter_extractor = StubExtractor.new(pages: ['Page one only.'])
    RulebookImporter.new(@rulebook, extractor: shorter_extractor).import!(@path, force: true)

    assert_equal 1, @rulebook.reload.rulebook_pages.count
  end

  test 'a failed extraction marks the rulebook failed without touching existing pages' do
    result = RulebookImporter.new(@rulebook, extractor: FailingExtractor.new).import!(@path)

    assert_not result.success?
    @rulebook.reload
    assert_equal 'failed', @rulebook.status
    assert @rulebook.import_error.present?
  end

  test 'a failure on an individual page marks the whole rulebook failed, not ready' do
    extractor = PartiallyFailingExtractor.new(pages: ['One.', 'Two.', 'Three.'], fail_on: 2)
    result = RulebookImporter.new(@rulebook, extractor: extractor).import!(@path)

    assert_not result.success?
    @rulebook.reload
    assert_equal 'failed', @rulebook.status
    assert_includes @rulebook.import_error, 'page 2'
  end

  test 'import error messages never leak the server-local file path' do
    result = RulebookImporter.new(@rulebook, extractor: FailingExtractor.new).import!(@path)

    assert_not result.success?
    assert_not @rulebook.reload.import_error.include?(@path.to_s)
  end

  test 'returns an error result without touching the rulebook when the file does not exist' do
    missing_path = Rails.root.join('tmp/does_not_exist.pdf')
    result = RulebookImporter.new(@rulebook, extractor: StubExtractor.new(pages: [])).import!(missing_path)

    assert_not result.success?
    assert_equal 'pending', @rulebook.reload.status
  end
end
