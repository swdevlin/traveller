module SectorsHelper
  include SubsectorsHelper

  def sector_hex_grid_svg_dimensions
    width  = SVG_PADDING * 2 + 32 * HEX_WIDTH * 0.75 + HEX_WIDTH * 0.25
    height = SVG_PADDING * 2 + 40 * HEX_HEIGHT + HEX_HEIGHT * 0.5
    [width.round, height.round]
  end
end
