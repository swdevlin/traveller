# frozen_string_literal: true

# Lays CommonMark out as formatted text for an SVG page. SVG has no text flow, so this walks the
# Markdown syntax tree and works out where every run of text goes.
#
# Everything is set in a monospaced face (JetBrains Mono, 0.6 em per glyph, bold and italic
# included), so line wrapping is exact without measuring text. Units are whatever the caller's
# SVG uses (millimetres for the handout PDFs); coordinates are relative to the block's top left.
#
# When the content does not fit +max_height+ it is cut off and the last line becomes
# TRUNCATION_MARKER.
class SvgMarkdownLayout
  CHAR_RATIO = 0.6
  LINE_RATIO = 1.45
  # Line spacings tried in turn by .fit, loosest first.
  FIT_LINE_RATIOS = [1.45, 1.35, 1.25].freeze
  ASCENT_RATIO = 1.05
  GAP_RATIO = 0.5
  HEADING_SCALE = { 1 => 1.3, 2 => 1.15 }.freeze
  QUOTE_INDENT_RATIO = 1.2
  CODE_PADDING_RATIO = 0.3
  TRUNCATION_MARKER = '… full record held in the survey archive'

  # style is a Hash that may hold :bold, :italic, :strike, :underline and :code.
  Text = Struct.new(:x, :y, :size, :text, :style, keyword_init: true)
  # kind is :code (behind inline code), :box (code block), :quote (block quote bar) or :rule.
  Rect = Struct.new(:kind, :x, :y, :width, :height, keyword_init: true)
  Result = Struct.new(:texts, :rects, :height, :truncated, keyword_init: true)

  # Lays the markdown out as large as it can go, down to +min_size+: first at +size+ with the line
  # spacing tightened step by step, then at smaller sizes (spacing as tight as it goes). If it still
  # does not fit at +min_size+, the result is cut off with the truncation marker as usual.
  def self.fit(markdown, width:, max_height:, size: 2.4, min_size: 1.8, size_step: 0.1)
    sizes = (size.to_f).step(min_size.to_f, -size_step).to_a
    candidates = FIT_LINE_RATIOS.map { |ratio| [sizes.first, ratio] } +
                 sizes.drop(1).map { |smaller| [smaller, FIT_LINE_RATIOS.last] }
    result = nil
    candidates.each do |candidate_size, ratio|
      result = new(markdown, width: width, max_height: max_height, size: candidate_size, line_ratio: ratio).layout
      return result unless result.truncated
    end
    result
  end

  def initialize(markdown, width:, max_height:, size: 2.4, line_ratio: LINE_RATIO)
    @line_ratio = line_ratio
    @markdown = markdown.to_s.encode(Encoding::UTF_8)
    @width = width.to_f
    @max_height = max_height.to_f
    @size = size.to_f
  end

  def layout
    result = run(@max_height)
    return result unless result.truncated

    run(@max_height - line_height(@size), marker: true)
  end

  private

  def run(limit, marker: false)
    @limit = limit
    @texts = []
    @rects = []
    @y = 0.0
    @marker = nil
    @truncated = false

    document = Commonmarker.parse(@markdown, options: MarkdownRenderer::OPTIONS)
    catch(:full) { blocks(document, 0.0, @width, tight: false) }
    place_truncation_marker if marker && @truncated

    Result.new(texts: @texts, rects: @rects, height: @y, truncated: @truncated)
  end

  def place_truncation_marker
    @texts << Text.new(x: 0.0, y: @y + (@size * ASCENT_RATIO), size: @size,
                       text: TRUNCATION_MARKER, style: { italic: true })
    @y += line_height(@size)
  end

  def line_height(size)
    size * @line_ratio
  end

  def char_width(size)
    size * CHAR_RATIO
  end

  def columns(width, size)
    [(width / char_width(size)).floor, 1].max
  end

  def ensure_room(height)
    return if @y + height <= @limit + 0.001

    @truncated = true
    throw :full
  end

  def blocks(parent, x, width, tight:)
    first = true
    parent.each do |node|
      @y += line_height(@size) * GAP_RATIO unless first || tight
      first = false
      block(node, x, width)
    end
  end

  def block(node, x, width)
    case node.type
    when :paragraph then paragraph(inline_atoms(node), x, width, @size)
    when :heading then heading(node, x, width)
    when :list then list(node, x, width)
    when :block_quote then block_quote(node, x, width)
    when :code_block then code_block(node, x, width)
    when :thematic_break then thematic_break(x, width)
    when :table then table(node, x, width)
    end
  end

  def heading(node, x, width)
    size = @size * HEADING_SCALE.fetch(node.header_level, 1.0)
    atoms = inline_atoms(node).map { |text, style| [text, style.is_a?(Hash) ? style.merge(bold: true) : style] }
    paragraph(atoms, x, width, size)
  end

  def paragraph(atoms, x, width, size)
    height = line_height(size)
    wrap(atoms, columns(width, size)).each do |segments|
      ensure_room(height)
      place(segments, x, @y, size)
      @y += height
    end
  end

  def list(node, x, width)
    items = []
    node.each { |item| items << item }
    ordered = node.list_type == :ordered
    start = ordered ? (node.list_start || 1) : 1
    marker_columns = ordered ? (start + items.size - 1).to_s.length + 2 : 2
    indent = marker_columns * char_width(@size)

    items.each_with_index do |item, index|
      @marker = [x, item_marker(item, ordered, start + index)]
      blocks(item, x + indent, width - indent, tight: true)
      @marker = nil
    end
  end

  def item_marker(item, ordered, number)
    if item.type == :taskitem
      item_checked?(item) ? '☑' : '☐'
    elsif ordered
      "#{number}."
    else
      '•'
    end
  end

  # Commonmarker exposes no accessor for a task item's state; it only appears in the rendered HTML.
  def item_checked?(item)
    item.to_html(options: MarkdownRenderer::OPTIONS).include?('checked')
  end

  def block_quote(node, x, width)
    indent = @size * QUOTE_INDENT_RATIO
    top = @y
    blocks(node, x + indent, width - indent, tight: false)
    @rects << Rect.new(kind: :quote, x: x, y: top, width: @size * 0.25, height: @y - top) if @y > top
  end

  def code_block(node, x, width)
    lines = node.string_content.to_s.lines.map(&:chomp)
    return if lines.empty?

    pad = @size * CODE_PADDING_RATIO
    height = line_height(@size)
    ensure_room((lines.size * height) + (2 * pad))

    cols = columns(width - (2 * pad), @size)
    @rects << Rect.new(kind: :box, x: x, y: @y, width: width, height: (lines.size * height) + (2 * pad))
    @y += pad
    lines.each do |line|
      line = "#{line[0, cols - 1]}…" if line.length > cols
      place([[line, {}, 0]], x + pad, @y, @size)
      @y += height
    end
    @y += pad
  end

  def thematic_break(x, width)
    ensure_room(line_height(@size))
    @rects << Rect.new(kind: :rule, x: x, y: @y + (line_height(@size) / 2), width: width, height: @size * 0.08)
    @y += line_height(@size)
  end

  def table(node, x, width)
    rows = []
    node.each do |row|
      cells = []
      row.each { |cell| cells << inline_atoms(cell) }
      rows << cells
    end
    column_count = rows.map(&:size).max.to_i
    return if column_count.zero?

    column_width = width / column_count
    height = line_height(@size)
    rows.each_with_index do |cells, row_index|
      wrapped = cells.map do |atoms|
        atoms = atoms.map { |text, style| [text, style.is_a?(Hash) ? style.merge(bold: true) : style] } if row_index.zero?
        wrap(atoms, columns(column_width - char_width(@size), @size))
      end
      row_height = [wrapped.map(&:size).max, 1].max * height
      ensure_room(row_height)
      wrapped.each_with_index do |lines, column|
        lines.each_with_index do |segments, line|
          place(segments, x + (column * column_width), @y + (line * height), @size)
        end
      end
      @y += row_height
      @rects << Rect.new(kind: :rule, x: x, y: @y - (height * 0.1), width: width, height: @size * 0.06)
    end
  end

  # Flattens the inline children of +node+ into [text, style] atoms, with :br for hard breaks.
  def inline_atoms(node, style = {}, atoms = [])
    node.each do |child|
      case child.type
      when :text then atoms << [child.string_content.to_s, style]
      when :code then atoms << [child.string_content.to_s, style.merge(code: true)]
      when :softbreak then atoms << [' ', style]
      when :linebreak then atoms << [:br, nil]
      when :strong then inline_atoms(child, style.merge(bold: true), atoms)
      when :emph then inline_atoms(child, style.merge(italic: true), atoms)
      when :strikethrough then inline_atoms(child, style.merge(strike: true), atoms)
      when :link then inline_atoms(child, style.merge(underline: true), atoms)
      when :html_inline then next
      else inline_atoms(child, style, atoms)
      end
    end
    atoms
  end

  # Greedy word wrap. Returns lines, each an array of [text, style, column] segments.
  def wrap(atoms, cols)
    lines = []
    line = []
    col = 0
    pending_space = false
    flush = lambda do
      lines << line
      line = []
      col = 0
      pending_space = false
    end

    atoms.each do |text, style|
      if text == :br
        flush.call
        next
      end

      text.scan(/\s+|\S+/).each do |token|
        if token.match?(/\A\s/)
          pending_space = true unless col.zero?
          next
        end

        word = token
        loop do
          space = pending_space ? 1 : 0
          if col + space + word.length <= cols
            if space == 1
              space_style = line.last && line.last[1] == style ? style : {}
              push_segment(line, ' ', space_style, col)
              col += 1
            end
            push_segment(line, word, style, col)
            col += word.length
            pending_space = false
            break
          elsif col.positive?
            flush.call
          else
            push_segment(line, word[0, cols], style, 0)
            word = word[cols..]
            flush.call
          end
        end
      end
    end
    lines << line unless line.empty?
    lines
  end

  def push_segment(line, text, style, col)
    last = line.last
    if last && last[1] == style && last[2] + last[0].length == col
      last[0] += text
    else
      line << [text.dup, style, col]
    end
  end

  def place(segments, x, top, size)
    baseline = top + (size * ASCENT_RATIO)
    if @marker
      @texts << Text.new(x: @marker[0], y: baseline, size: size, text: @marker[1], style: {})
      @marker = nil
    end

    segments.each do |text, style, col|
      segment_x = x + (col * char_width(size))
      if style[:code]
        @rects << Rect.new(kind: :code, x: segment_x, y: top + (size * 0.1),
                           width: text.length * char_width(size), height: size * 1.2)
      end
      @texts << Text.new(x: segment_x, y: baseline, size: size, text: text, style: style)
    end
  end
end
