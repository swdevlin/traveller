require 'test_helper'

class SvgRasteriserTest < ActiveSupport::TestCase
  TEXTURED_SVG = <<~SVG.freeze
    <svg xmlns="http://www.w3.org/2000/svg" width="40" height="20">
      <defs>
        <filter id="noise" x="0" y="0" width="100%" height="100%">
          <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="1"/>
        </filter>
        <pattern id="texture" patternUnits="userSpaceOnUse" width="20" height="20">
          <rect width="20" height="20" filter="url(#noise)"/>
        </pattern>
      </defs>
      <polygon points="0,0 40,0 40,20 0,20" fill="url(#texture)"/>
    </svg>
  SVG

  test 'filtered patterns are baked to an image before rendering' do
    baked = SvgRasteriser.new(TEXTURED_SVG).send(:bake_patterns, TEXTURED_SVG)
    assert_includes baked, 'data:image/png;base64,'
    assert_no_match(/<rect[^>]*filter=/, baked)
  end

  test 'baked output matches the direct render' do
    direct, = Open3.capture2('rsvg-convert', '-f', 'png', stdin_data: TEXTURED_SVG, binmode: true)
    assert_equal direct, SvgRasteriser.new(TEXTURED_SVG).png
  end

  test 'svg without filtered patterns is left untouched' do
    svg = '<svg xmlns="http://www.w3.org/2000/svg" width="4" height="4"><rect width="4" height="4"/></svg>'
    assert_equal svg, SvgRasteriser.new(svg).send(:bake_patterns, svg)
  end
end
