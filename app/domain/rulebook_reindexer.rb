# frozen_string_literal: true

class RulebookReindexer
  def initialize(rulebook)
    @rulebook = rulebook
  end

  def call
    normalizer = TextNormalizer.new(header_footer_patterns: @rulebook.header_footer_patterns, rulebook_title: @rulebook.title)

    ActiveRecord::Base.transaction do
      @rulebook.rulebook_pages.find_each do |page|
        result = normalizer.call(page.body)
        # Reindexing only re-normalizes already-stored raw body text; it never re-extracts
        # from the source PDF. A page imported before markdown-heading detection existed has
        # no `#`-style heading in its stored body, so a rerun must never null out a heading a
        # prior import already set — only ever add/replace with a newly-found one.
        page.update!(heading: result.heading || page.heading, normalized_body: result.normalized_body,
                     item_lines: result.item_lines, bold_text: result.bold_text)
      end
    end
  end
end
