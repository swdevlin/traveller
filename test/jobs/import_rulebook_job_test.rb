require 'test_helper'

class ImportRulebookJobTest < ActiveJob::TestCase
  setup do
    @rulebook = rulebooks(:pending_import)
    @path = file_fixture('sample_rulebook.pdf')
  end

  test 'imports the fixture PDF and marks the rulebook ready' do
    ImportRulebookJob.perform_now(@rulebook.id, @path)

    @rulebook.reload
    assert_equal 'ready', @rulebook.status
    assert_equal 3, @rulebook.rulebook_pages.count
  end

  test 'marks the rulebook failed, never ready, when extraction raises' do
    raising_extractor = Object.new
    def raising_extractor.page_count(_path)
      raise PdfTextExtractor::ExtractionError, 'boom'
    end

    stub_new(PdfTextExtractor, raising_extractor) do
      ImportRulebookJob.perform_now(@rulebook.id, @path)
    end

    @rulebook.reload
    assert_equal 'failed', @rulebook.status
    assert @rulebook.import_error.present?
  end

  test 'a crash inside perform still marks the rulebook failed rather than leaving it processing' do
    crashing_importer = Object.new
    def crashing_importer.import!(*args, **kwargs)
      raise 'unexpected crash'
    end

    stub_new(RulebookImporter, crashing_importer) do
      ImportRulebookJob.perform_now(@rulebook.id, @path)
    end

    @rulebook.reload
    assert_equal 'failed', @rulebook.status
    assert_includes @rulebook.import_error, 'unexpected crash'
  end

  test 'cleanup_after: true deletes the file after a successful import' do
    staged_path = Rails.root.join('tmp', "cleanup-test-#{SecureRandom.hex(4)}.pdf")
    FileUtils.cp(@path, staged_path)

    ImportRulebookJob.perform_now(@rulebook.id, staged_path, cleanup_after: true)

    assert_not File.exist?(staged_path)
  end

  test 'cleanup_after: true deletes the file even when import fails' do
    staged_path = Rails.root.join('tmp', "cleanup-fail-test-#{SecureRandom.hex(4)}.pdf")
    FileUtils.cp(@path, staged_path)
    raising_extractor = Object.new
    def raising_extractor.page_count(_path)
      raise PdfTextExtractor::ExtractionError, 'boom'
    end

    stub_new(PdfTextExtractor, raising_extractor) do
      ImportRulebookJob.perform_now(@rulebook.id, staged_path, cleanup_after: true)
    end

    assert_not File.exist?(staged_path)
  end

  test 'cleanup_after defaults to false, leaving the file in place (rake-task behavior unchanged)' do
    ImportRulebookJob.perform_now(@rulebook.id, @path)
    assert File.exist?(@path)
  end
end
