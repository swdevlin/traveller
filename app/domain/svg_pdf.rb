# frozen_string_literal: true

require 'open3'

# Converts our own SVG output to a PDF with the rsvg-convert CLI. The page size is taken from the
# SVG's width and height, so give it millimetre units for print.
class SvgPdf
  def self.render(svg)
    data, status = Open3.capture2('rsvg-convert', '-f', 'pdf', stdin_data: svg, binmode: true)
    raise "rsvg-convert failed (exit #{status.exitstatus})" unless status.success?

    data
  end
end
