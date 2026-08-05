require 'test_helper'

class TextNormalizerTest < ActiveSupport::TestCase
  test 'strips null bytes' do
    result = TextNormalizer.new.call("hello\u0000world")
    assert_equal 'helloworld', result.normalized_body
  end

  test 'repairs line-break hyphenation' do
    result = TextNormalizer.new.call("hyper-\nspace")
    assert_equal 'hyperspace', result.normalized_body
  end

  test 'collapses repeated spaces and tabs' do
    result = TextNormalizer.new.call("a  b\t\tc")
    assert_equal 'a b c', result.normalized_body
  end

  test 'preserves paragraph boundaries while collapsing excess blank lines' do
    result = TextNormalizer.new.call("first paragraph\n\n\n\n\nsecond paragraph")
    assert_equal "first paragraph\n\nsecond paragraph", result.normalized_body
  end

  test 'strips a known purchaser watermark pattern' do
    result = TextNormalizer.new.call('This electronic copy of the book is licensed to John Smith.')
    assert_equal '', result.normalized_body.strip
  end

  test 'strips a purchaser name and order number watermark' do
    result = TextNormalizer.new.call('Shawn W Devlin (Order #1234567)')
    assert_equal '', result.normalized_body.strip
  end

  test 'strips a configured per-rulebook header/footer pattern' do
    normalizer = TextNormalizer.new(header_footer_patterns: ['Traveller Core Rulebook \\d+'])
    result = normalizer.call("Traveller Core Rulebook 42\nActual content here.")
    assert_equal 'Actual content here.', result.normalized_body.strip
  end

  test 'ignores an invalid configured pattern rather than raising' do
    normalizer = TextNormalizer.new(header_footer_patterns: ['(unterminated'])
    assert_nothing_raised { normalizer.call('some text') }
  end

  test 'does not alter body text unnecessarily' do
    result = TextNormalizer.new.call('Ordinary paragraph with no issues.')
    assert_equal 'Ordinary paragraph with no issues.', result.normalized_body
  end

  test 'handles nil input safely' do
    result = TextNormalizer.new.call(nil)
    assert_equal '', result.normalized_body
    assert_nil result.heading
  end

  test 'extracts a single markdown heading' do
    result = TextNormalizer.new.call("# The Rise and Fall of the Darrians\n\nBody text.")
    assert_equal 'The Rise and Fall of the Darrians', result.heading
  end

  test 'joins multiple headings found on one page' do
    result = TextNormalizer.new.call("# First Section\n\nSome text.\n\n## Second Section\n\nMore text.")
    assert_equal 'First Section / Second Section', result.heading
  end

  test 'heading is nil when the page has no markdown heading' do
    result = TextNormalizer.new.call('Plain body text with no heading.')
    assert_nil result.heading
  end

  test 'strips heading markdown syntax from the body but keeps the heading text' do
    result = TextNormalizer.new.call("# A Heading\n\nBody text.")
    assert_equal "A Heading\n\nBody text.", result.normalized_body
  end

  test 'strips bold and italic emphasis markers' do
    result = TextNormalizer.new.call('Some **bold** and _italic_ and __also bold__ and *also italic* text.')
    assert_equal 'Some bold and italic and also bold and also italic text.', result.normalized_body
  end

  test 'strips markdown image references' do
    result = TextNormalizer.new.call('Text before. ![alt text](image.png) Text after.')
    assert_equal 'Text before. Text after.', result.normalized_body
  end

  test 'strips markdown horizontal rules' do
    result = TextNormalizer.new.call("Paragraph one.\n\n---\n\nParagraph two.")
    assert_equal "Paragraph one.\n\nParagraph two.", result.normalized_body
  end

  test 'strips emphasis markers within an extracted heading' do
    result = TextNormalizer.new.call("# **The Rise and Fall of the Darrians**\n\nBody text.")
    assert_equal 'The Rise and Fall of the Darrians', result.heading
  end

  test 'falls back to a plain ALL-CAPS heading when there is no markdown heading' do
    result = TextNormalizer.new.call("DROYNE, CHIRPERS AND\nRELATED BEINGS\nAs already noted, the Droyne evolved.")
    assert_equal 'DROYNE, CHIRPERS AND RELATED BEINGS', result.heading
  end

  test 'skips a letter-spaced decorative label ahead of a plain ALL-CAPS heading' do
    result = TextNormalizer.new.call("C H A P T E R – F O U R T E E N\n\nDROYNE, CHIRPERS AND\nRELATED BEINGS\n\nBody prose starts here.")
    assert_equal 'DROYNE, CHIRPERS AND RELATED BEINGS', result.heading
  end

  test 'does not treat a purely letter-spaced title as a heading' do
    result = TextNormalizer.new.call("H i g h G u a r d\n\nBody prose starts here.")
    assert_nil result.heading
  end

  test 'skips a leading folio number without losing the ALL-CAPS heading after it' do
    result = TextNormalizer.new.call("144\n\nDROYNE, CHIRPERS AND\nRELATED BEINGS\n\nBody prose starts here.")
    assert_equal 'DROYNE, CHIRPERS AND RELATED BEINGS', result.heading
  end

  test 'caps fallback does not fire on a page that opens with ordinary prose' do
    result = TextNormalizer.new.call('An alternative theory suggests that in some cases the bizarre behaviour.')
    assert_nil result.heading
  end

  test 'trims a merged two-column stat block down to the title segment' do
    result = TextNormalizer.new.call("FRINGE COLONIST                                        STR    —     INT       —    BENEFITS\n\nSome career description text.")
    assert_equal 'FRINGE COLONIST', result.heading
  end

  test 'drops a leading noise segment with no letters when trimming a merged column line' do
    result = TextNormalizer.new.call("14       TRUTHER\n\nSome career description text.")
    assert_equal 'TRUTHER', result.heading
  end

  test 'does not treat a running header repeating the rulebook title as a heading' do
    normalizer = TextNormalizer.new(rulebook_title: 'Core Rulebook')
    result = normalizer.call("CORE RULEBOOK\n\nChapter 3: Starships\n\nSome body text.")
    assert_nil result.heading
  end

  test 'skips the running rulebook title but still finds a plain ALL-CAPS heading after it' do
    normalizer = TextNormalizer.new(rulebook_title: 'Core Rulebook')
    result = normalizer.call("CORE RULEBOOK\n\nSTARSHIPS\n\nSome body text.")
    assert_equal 'STARSHIPS', result.heading
  end

  test 'captures a line with a credit cost token into item_lines' do
    result = TextNormalizer.new.call("Laser Sniper 12 600m 5D+3 4 Cr9000 6 Cr250 Scope,\nOrdinary prose with no cost.")
    assert_equal 'Laser Sniper 12 600m 5D+3 4 Cr9000 6 Cr250 Scope,', result.item_lines
  end

  test 'joins multiple item lines with a space' do
    result = TextNormalizer.new.call("Laser Pistol 9 20m 3D 2 Cr2000 100 Cr1000 Zero-G\nStunner 8 5m 2D 0.5 Cr500 100 Cr200 Stun,")
    assert_equal 'Laser Pistol 9 20m 3D 2 Cr2000 100 Cr1000 Zero-G Stunner 8 5m 2D 0.5 Cr500 100 Cr200 Stun,', result.item_lines
  end

  test 'item_lines is nil when no line has a credit cost token' do
    result = TextNormalizer.new.call('Ordinary paragraph with no issues.')
    assert_nil result.item_lines
  end

  test 'captures double-asterisk bold spans into bold_text' do
    result = TextNormalizer.new.call('Plain text with a **critical rule** inside it.')
    assert_equal 'critical rule', result.bold_text
  end

  test 'captures double-underscore bold spans into bold_text' do
    result = TextNormalizer.new.call('Plain text with a __critical rule__ inside it.')
    assert_equal 'critical rule', result.bold_text
  end

  test 'joins multiple bold spans with a space' do
    result = TextNormalizer.new.call('The **Referee** decides. Consult the **Traveller Bestiary**.')
    assert_equal 'Referee Traveller Bestiary', result.bold_text
  end

  test 'does not treat single-asterisk italics as bold' do
    result = TextNormalizer.new.call('Some *italic* text with no bold.')
    assert_nil result.bold_text
  end

  test 'bold_text is nil when there is no emphasis' do
    result = TextNormalizer.new.call('Ordinary paragraph with no emphasis.')
    assert_nil result.bold_text
  end
end
