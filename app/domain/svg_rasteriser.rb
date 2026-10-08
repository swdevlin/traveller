# frozen_string_literal: true

require 'base64'
require 'nokogiri'
require 'open3'

# Rasterises our own SVG output. ActiveStorage globally disables libvips's "untrusted"
# loaders (including svgload) at boot via Vips.block_untrusted(true), so the SVG goes
# through the rsvg-convert CLI to PNG first; PNG loading isn't blocked, so libvips can
# still encode the result.
#
# librsvg re-renders a <pattern> tile for every shape that uses it. Our maps fill ~2,500
# hexes with a feTurbulence texture pattern, which took ~28s. Each pattern is therefore
# rendered to a PNG once and swapped in as an <image>, giving byte-identical output in ~1s.
class SvgRasteriser
  def self.webp(svg)
    new(svg).webp
  end

  def initialize(svg)
    @svg = svg
  end

  def webp
    Vips::Image.new_from_buffer(png, '').webpsave_buffer
  end

  def png
    render_png(bake_patterns(@svg))
  end

  private

  SVG_NS = { 's' => 'http://www.w3.org/2000/svg' }.freeze

  def render_png(svg)
    data, status = Open3.capture2('rsvg-convert', '-f', 'png', stdin_data: svg, binmode: true)
    raise "rsvg-convert failed (exit #{status.exitstatus})" unless status.success?

    data
  end

  def bake_patterns(svg)
    doc = Nokogiri::XML(svg)
    patterns = doc.xpath('//s:pattern[.//*[@filter]]', SVG_NS)
    return svg if patterns.empty?

    filters = doc.xpath('//s:filter', SVG_NS).map(&:to_xml).join
    patterns.each { |pattern| bake_pattern(doc, pattern, filters) }
    doc.to_xml
  end

  def bake_pattern(doc, pattern, filters)
    width = pattern['width']
    height = pattern['height']
    tile = %(<svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}">) +
           "<defs>#{filters}</defs>#{pattern.children.map(&:to_xml).join}</svg>"

    image = Nokogiri::XML::Node.new('image', doc)
    image['width'] = width
    image['height'] = height
    image['href'] = "data:image/png;base64,#{Base64.strict_encode64(render_png(tile))}"
    pattern.children.each(&:remove)
    pattern.add_child(image)
  end
end
