require 'test_helper'
require 'open3'
require 'json'

# Exercises libexec/extract_rulebook.py directly as a subprocess (not through
# PdfTextExtractor), so a broken/missing Python dependency or venv fails loudly in CI
# rather than being silently mocked away.
class ExtractRulebookScriptTest < ActiveSupport::TestCase
  SCRIPT_PATH = Rails.root.join('libexec', 'extract_rulebook.py')

  setup do
    @path = file_fixture('sample_rulebook.pdf')
    @python = Rails.application.config.x.pdf_extractor_python
  end

  test 'prints only a valid JSON document to stdout on success' do
    stdout, _stderr, status = Open3.capture3(@python, SCRIPT_PATH.to_s, @path.to_s)

    assert status.success?
    document = JSON.parse(stdout)
    assert_equal 1, document['schema_version']
    assert document['pymupdf4llm_version'].present?
    assert document['pymupdf_version'].present?
    assert_equal 3, document['page_count']
    assert_equal 3, document['pages'].size
  end

  test 'exits non-zero with a stderr message and empty stdout for a missing file' do
    missing_path = Rails.root.join('tmp/does_not_exist.pdf')
    stdout, stderr, status = Open3.capture3(@python, SCRIPT_PATH.to_s, missing_path.to_s)

    assert_not status.success?
    assert_equal '', stdout
    assert stderr.present?
  end

  test 'exits non-zero with a stderr message for a path that is not a regular file' do
    stdout, stderr, status = Open3.capture3(@python, SCRIPT_PATH.to_s, Rails.root.join('tmp').to_s)

    assert_not status.success?
    assert_equal '', stdout
    assert stderr.present?
  end
end
