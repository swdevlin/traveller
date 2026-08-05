# frozen_string_literal: true

class TextNormalizer
  Result = Struct.new(:heading, :normalized_body, keyword_init: true)

  PURCHASER_WATERMARK_PATTERNS = [
    /this (?:electronic )?copy .{0,80} is licensed to .+/i,
    /property of .+ do not (?:re)?distribute/i,
    /\b(?:[A-Za-z][A-Za-z'.-]*\s+){1,4}\(order #\d+\)/i
  ].freeze

  MARKDOWN_HEADING_LINE = /^\#{1,6}\s+(.+)$/
  MARKDOWN_EMPHASIS = /\*\*(.+?)\*\*|__(.+?)__|\*(.+?)\*|_(.+?)_/
  MARKDOWN_IMAGE = /!\[.*?\]\(.*?\)/
  MARKDOWN_HORIZONTAL_RULE = /^-{3,}\s*$/
  MARKDOWN_HEADING_PREFIX = /^\#{1,6}\s+/

  # Many scanned rulebooks never get a markdown `#` heading from the PDF-to-markdown
  # extraction, but a section-title page still opens with one or two plain, ALL-CAPS
  # lines (e.g. "DROYNE, CHIRPERS AND\nRELATED BEINGS") before the body prose starts.
  # This does NOT attempt to recover decorative letter-spaced titles (e.g. a cover
  # page's "H i g h G u a r d", or a "C H A P T E R – F O U R T E E N" label) —
  # collapsing those correctly is a separate, fiddlier problem.
  LETTER_SPACED_TOKEN_RATIO = 0.6
  MIN_LETTER_SPACED_TOKENS = 3

  # A two-column layout (e.g. side-by-side stat block tables) often gets flattened onto
  # one text line by the PDF extraction, with a wide gap where the columns met — e.g.
  # "FRINGE COLONIST                    STR  —  INT  —  BENEFITS". A real title is never
  # padded like this, so a gap this wide marks the boundary of the actual heading text.
  COLUMN_GAP = / {3,}/

  def initialize(header_footer_patterns: [], rulebook_title: nil)
    @rulebook_patterns = Array(header_footer_patterns).filter_map { |pattern| safe_regexp(pattern) }
    @rulebook_title_key = normalize_for_comparison(rulebook_title)
  end

  def call(raw_text)
    text = raw_text.to_s.dup
    text = text.delete("\u0000")
    heading = extract_heading(text)
    text = strip_markdown_syntax(text)
    text = strip_patterns(text, PURCHASER_WATERMARK_PATTERNS)
    text = strip_patterns(text, @rulebook_patterns)
    text = repair_hyphenation(text)
    Result.new(heading: heading, normalized_body: normalize_whitespace(text))
  end

  private

  def safe_regexp(pattern)
    Regexp.new(pattern)
  rescue RegexpError
    nil
  end

  def extract_heading(text)
    headings = text.scan(MARKDOWN_HEADING_LINE).flatten.map { |line| strip_emphasis(line).strip }.reject(&:blank?)
    headings.join(' / ').presence || extract_caps_heading(text)
  end

  def extract_caps_heading(text)
    caps_lines = []

    text.to_s.each_line do |raw_line|
      line = strip_emphasis(raw_line).strip
      next if line.blank?
      next if rulebook_title_line?(line) # a running header repeating the book's own title, not a section heading
      next unless line.match?(/[A-Za-z]/) # folio numbers, rules, bullets: noise, not a block boundary

      if letter_spaced?(line)
        break if caps_lines.any?

        next # decorative label (e.g. a "CHAPTER" line) ahead of the real title: skip, don't capture
      end

      line = strip_column_gap(line)
      break unless all_caps_line?(line)

      caps_lines << line
    end

    caps_lines.join(' ').presence
  end

  def all_caps_line?(line)
    !line.match?(/[a-z]/)
  end

  def letter_spaced?(line)
    tokens = line.split(/\s+/)
    return false if tokens.size < MIN_LETTER_SPACED_TOKENS

    single_char_tokens = tokens.count { |token| token.length == 1 }
    single_char_tokens.to_f / tokens.size >= LETTER_SPACED_TOKEN_RATIO
  end

  def strip_column_gap(line)
    line.split(COLUMN_GAP).find { |segment| segment.match?(/[A-Za-z]/) } || line
  end

  def rulebook_title_line?(line)
    @rulebook_title_key.present? && normalize_for_comparison(line) == @rulebook_title_key
  end

  def normalize_for_comparison(text)
    text.to_s.gsub(/[^A-Za-z0-9]+/, ' ').strip.upcase
  end

  def strip_markdown_syntax(text)
    text
      .gsub(MARKDOWN_IMAGE, '')
      .gsub(MARKDOWN_HORIZONTAL_RULE, '')
      .gsub(MARKDOWN_HEADING_PREFIX, '')
      .then { |t| strip_emphasis(t) }
  end

  def strip_emphasis(text)
    text.gsub(MARKDOWN_EMPHASIS) { $1 || $2 || $3 || $4 }
  end

  def strip_patterns(text, patterns)
    patterns.reduce(text) { |t, pattern| t.gsub(pattern, '') }
  end

  def repair_hyphenation(text)
    text.gsub(/(\w)-\n(\w)/, '\1\2')
  end

  def normalize_whitespace(text)
    text
      .gsub(/[ \t]+/, ' ')
      .gsub(/\n{3,}/, "\n\n")
      .strip
  end
end
