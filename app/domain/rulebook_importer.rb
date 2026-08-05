# frozen_string_literal: true

require 'digest'
require 'pathname'

class RulebookImporter
  Result = Struct.new(:value, :errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  def initialize(rulebook, extractor: PdfTextExtractor.new)
    @rulebook = rulebook
    @extractor = extractor
  end

  def import!(path, force: false)
    path = Pathname.new(path)
    return Result.new(errors: ["File not found: #{path.basename}"]) unless path.exist?

    checksum = Digest::SHA256.file(path).hexdigest
    if !force && @rulebook.status == 'ready' && @rulebook.file_checksum == checksum
      return Result.new(value: @rulebook)
    end

    @rulebook.update!(status: 'processing', import_error: nil)

    begin
      extraction = @extractor.extract(path)
    rescue PdfTextExtractor::ExtractionError, StandardError => e
      @rulebook.update!(status: 'failed', import_error: scrub_path(e.message, path))
      return Result.new(errors: [e.message])
    end

    normalizer = TextNormalizer.new(header_footer_patterns: @rulebook.header_footer_patterns, rulebook_title: @rulebook.title)
    page_errors = []

    extraction.pages.each do |page_data|
      result = normalizer.call(page_data.text)
      page = @rulebook.rulebook_pages.find_or_initialize_by(pdf_page_number: page_data.page_number)
      page.body = page_data.text
      page.heading = result.heading
      page.normalized_body = result.normalized_body
      page.item_lines = result.item_lines
      page.bold_text = result.bold_text
      page.save!
    rescue StandardError => e
      page_errors << "page #{page_data.page_number}: #{e.message}"
    end

    ActiveRecord::Base.transaction do
      if page_errors.empty?
        @rulebook.rulebook_pages.where('pdf_page_number > ?', extraction.page_count).delete_all
        @rulebook.update!(status: 'ready', file_checksum: checksum, imported_at: Time.current, import_error: nil)
      else
        @rulebook.update!(status: 'failed', import_error: scrub_path(page_errors.join("\n"), path))
      end
    end

    page_errors.empty? ? Result.new(value: @rulebook) : Result.new(errors: page_errors)
  end

  private

  def scrub_path(text, path)
    text.to_s.gsub(path.to_s, path.basename.to_s)
  end
end
