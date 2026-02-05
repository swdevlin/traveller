module SubsectorsHelper
  HEX_SIZE = 40
  HEX_WIDTH = HEX_SIZE * 2
  HEX_HEIGHT = HEX_SIZE * Math.sqrt(3)
  SVG_PADDING = 20

  STAR_COLOURS = {
    'Blue' => '#6495ED',
    'Blue White' => '#CAE1FF',
    'Blue-White' => '#CAE1FF',
    'White' => '#FFFFFF',
    'Yellow White' => '#FFFACD',
    'Yellow-White' => '#FFFACD',
    'Yellow' => '#FFD700',
    'Light Orange' => '#FFB366',
    'Orange' => '#FFA500',
    'Orange Red' => '#FF6347',
    'Red' => '#FF4500',
    'Deep Dim Red' => '#8B0000',
    'Brown' => '#8B4513'
  }.freeze

  def hex_grid_svg_dimensions
    width = SVG_PADDING * 2 + 8 * HEX_WIDTH * 0.75 + HEX_WIDTH * 0.25
    height = SVG_PADDING * 2 + 10 * HEX_HEIGHT + HEX_HEIGHT * 0.5
    [width.round, height.round]
  end

  def hex_center(col, row)
    c = col - 1
    r = row - 1
    y_offset = col.even? ? HEX_HEIGHT * 0.5 : 0

    cx = SVG_PADDING + c * HEX_WIDTH * 0.75 + HEX_WIDTH / 2
    cy = SVG_PADDING + r * HEX_HEIGHT + y_offset + HEX_HEIGHT / 2
    [cx, cy]
  end

  def hex_polygon_points(cx, cy, size = HEX_SIZE)
    (0..5).map do |i|
      angle = Math::PI / 180 * (60 * i)
      x = cx + size * Math.cos(angle)
      y = cy + size * Math.sin(angle)
      "#{x.round(2)},#{y.round(2)}"
    end.join(' ')
  end

  def star_fill_colour(colour_name)
    STAR_COLOURS[colour_name] || colour_name || '#FFD700'
  end
end
