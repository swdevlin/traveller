# frozen_string_literal: true

require 'open3'
require 'json'
require 'pathname'

class PdfTextExtractor
  class ExtractionError < StandardError; end

  Page   = Struct.new(:page_number, :text, keyword_init: true)
  Result = Struct.new(:page_count, :pages, keyword_init: true)

  SCRIPT_PATH = Rails.root.join('libexec', 'extract_rulebook.py')

  def extract(path)
    stdout, stderr, status = Open3.capture3(python_executable, SCRIPT_PATH.to_s, path.to_s)
    raise ExtractionError, stderr.presence || "extract_rulebook.py failed on #{Pathname.new(path).basename}" unless status.success?

    build_result(stdout)
  end

  private

  def python_executable
    Rails.application.config.x.pdf_extractor_python
  end

  def build_result(stdout)
    document = JSON.parse(stdout)
    pages = document.fetch('pages').map do |page|
      Page.new(page_number: page.fetch('page_number'), text: page.fetch('text'))
    end
    Result.new(page_count: document.fetch('page_count'), pages: pages)
  rescue JSON::ParserError, KeyError => e
    raise ExtractionError, "malformed output from extract_rulebook.py: #{e.message}"
  end
end
