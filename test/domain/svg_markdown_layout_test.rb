require 'test_helper'

class SvgMarkdownLayoutTest < ActiveSupport::TestCase
  SIZE = 2.0
  CHAR = SIZE * SvgMarkdownLayout::CHAR_RATIO

  def layout(markdown, cols: 20, max_height: 500, size: SIZE)
    SvgMarkdownLayout.new(markdown, width: cols * size * SvgMarkdownLayout::CHAR_RATIO,
                                    max_height: max_height, size: size).layout
  end

  def rows(result)
    result.texts.group_by { |t| t.y.round(3) }.sort.map { |_y, ts| ts.sort_by(&:x) }
  end

  def row_text(row)
    row.map(&:text).join
  end

  test 'wraps words at the exact column count' do
    result = layout('aaaa bbbb cccc dddd eeee', cols: 10)

    assert_equal ['aaaa bbbb', 'cccc dddd', 'eeee'], rows(result).map { |r| row_text(r).strip }
  end

  test 'hard splits words longer than a line' do
    result = layout('abcdefghijkl', cols: 5)

    assert_equal %w[abcde fghij kl], rows(result).map { |r| row_text(r) }
  end

  test 'bold, italic and code runs keep their styles across a wrapped line' do
    result = layout('plain **bold text** and *it* `code`', cols: 40)
    styles = result.texts.to_h { |t| [t.text, t.style] }

    assert_equal({ bold: true }, styles['bold text'])
    assert_equal({ italic: true }, styles['it'])
    assert_equal({ code: true }, styles['code'])
    assert_equal 1, result.rects.count { |r| r.kind == :code }
  end

  test 'continuous styled words form a single run' do
    result = layout('**one two three**', cols: 40)

    assert_equal ['one two three'], result.texts.map(&:text)
  end

  test 'bullet lists get a marker and hanging indent' do
    result = layout("- aaaa bbbb cccc\n- dd", cols: 12)
    first_rows = rows(result)

    assert_equal '•', first_rows[0].first.text
    assert_in_delta 2 * CHAR, first_rows[0][1].x, 0.001
    assert_in_delta 2 * CHAR, first_rows[1].first.x, 0.001, 'wrapped line keeps the hanging indent'
    assert_equal '•', first_rows[2].first.text
  end

  test 'ordered lists are numbered from their start' do
    result = layout("3. aa\n4. bb", cols: 20)

    assert_equal ['3.', '4.'], rows(result).map { |r| r.first.text }
  end

  test 'nested lists indent further' do
    result = layout("- a\n  - b", cols: 20)
    markers = result.texts.select { |t| t.text == '•' }

    assert_operator markers.last.x, :>, markers.first.x
  end

  test 'task items use checkbox markers' do
    result = layout("- [x] done\n- [ ] todo", cols: 20)

    assert_equal %w[☑ ☐], result.texts.map(&:text).select { |t| %w[☑ ☐].include?(t) }
  end

  test 'headings are larger and bold' do
    result = layout("# Title\n\ntext", cols: 20)
    heading = result.texts.first

    assert_operator heading.size, :>, SIZE
    assert heading.style[:bold]
    assert_in_delta SIZE, result.texts.last.size, 0.001
  end

  test 'headings and paragraphs are separated by a gap' do
    tight = layout("a\nb", cols: 20)
    loose = layout("a\n\nb", cols: 20)

    assert_operator loose.height, :>, tight.height
  end

  test 'block quotes are indented and get a bar' do
    result = layout('> quoted', cols: 20)

    assert_operator result.texts.first.x, :>, 0
    assert_equal 1, result.rects.count { |r| r.kind == :quote }
  end

  test 'code blocks get a box and are clipped rather than wrapped' do
    result = layout("```\n#{'x' * 50}\n```", cols: 20)

    assert_equal 1, result.rects.count { |r| r.kind == :box }
    assert_equal 1, result.texts.size
    assert result.texts.first.text.end_with?('…')
  end

  test 'tables lay cells out in columns' do
    result = layout("| A | B |\n|---|---|\n| 1 | 2 |", cols: 20)
    row = rows(result).last

    assert_equal %w[1 2], row.map(&:text)
    assert_operator row.last.x, :>, row.first.x
  end

  test 'truncates with a marker when the content does not fit' do
    result = layout((['word'] * 60).join(' '), cols: 10, max_height: 12)

    assert result.truncated
    assert_equal SvgMarkdownLayout::TRUNCATION_MARKER, result.texts.last.text
    assert_operator result.height, :<=, 12.001
  end

  test 'content that fits is not truncated' do
    result = layout('short', cols: 20, max_height: 12)

    assert_not result.truncated
    assert_equal ['short'], result.texts.map(&:text)
  end

  test 'blank input produces no output' do
    result = layout('')

    assert_empty result.texts
    assert_equal 0, result.height
  end

  test 'fit leaves content that already fits at the requested size' do
    result = SvgMarkdownLayout.fit('short note', width: 50, max_height: 40, size: 2.0, min_size: 1.5)

    assert_not result.truncated
    assert_equal [2.0], result.texts.map(&:size).uniq
  end

  test 'fit tightens line spacing before shrinking the text' do
    markdown = (['word'] * 120).join(' ')
    plain = SvgMarkdownLayout.new(markdown, width: 50, max_height: 500, size: 2.0).layout
    # Room for the text at the tightest spacing but not at the default spacing.
    tight_height = plain.height * (SvgMarkdownLayout::FIT_LINE_RATIOS.last / SvgMarkdownLayout::LINE_RATIO) * 1.02
    result = SvgMarkdownLayout.fit(markdown, width: 50, max_height: tight_height, size: 2.0, min_size: 1.5)

    assert_not result.truncated
    assert_equal [2.0], result.texts.map(&:size).uniq
    assert_operator result.height, :<, plain.height
  end

  test 'fit shrinks the text when tighter spacing is not enough' do
    markdown = (['word'] * 120).join(' ')
    plain = SvgMarkdownLayout.new(markdown, width: 50, max_height: 500, size: 2.0).layout
    result = SvgMarkdownLayout.fit(markdown, width: 50, max_height: plain.height * 0.7, size: 2.0, min_size: 1.2)

    assert_not result.truncated
    assert_operator result.texts.map(&:size).max, :<, 2.0
    assert_operator result.texts.map(&:size).min, :>=, 1.2
  end

  test 'fit truncates at the minimum size when the content still does not fit' do
    markdown = (['word'] * 400).join(' ')
    result = SvgMarkdownLayout.fit(markdown, width: 50, max_height: 10, size: 2.0, min_size: 1.8)

    assert result.truncated
    assert_equal SvgMarkdownLayout::TRUNCATION_MARKER, result.texts.last.text
  end
end
