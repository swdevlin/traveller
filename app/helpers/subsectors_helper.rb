module SubsectorsHelper
  HEX_SIZE = 40
  HEX_WIDTH = HEX_SIZE * 2
  HEX_HEIGHT = HEX_SIZE * Math.sqrt(3)
  SVG_PADDING = 20

  FONT_HEX_LABEL    = 9
  FONT_STARPORT     = 10
  FONT_ALLEGIANCE   = 7
  FONT_UWP          = 9
  FONT_SYSTEM_NAME  = 12
  FONT_PARSEC_LABEL  = (FONT_SYSTEM_NAME * 1.5).round
  FONT_REGION_LABEL  = FONT_PARSEC_LABEL

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

  # Returns the 6 neighbouring [ux, uy] pairs for each hex edge (edge 0 = lower-right, clockwise)
  def hex_edge_neighbours(ux, uy)
    if ux.even?
      [[ux + 1, uy], [ux, uy - 1], [ux - 1, uy], [ux - 1, uy + 1], [ux, uy + 1], [ux + 1, uy + 1]]
    else
      [[ux + 1, uy - 1], [ux, uy - 1], [ux - 1, uy - 1], [ux - 1, uy], [ux, uy + 1], [ux + 1, uy]]
    end
  end

  # Returns [[x1,y1],[x2,y2]] pairs for each outer edge of this hex not shared with the border set
  def border_outer_edges(col, row, ux, uy, border_set)
    cx, cy = hex_center(col, row)
    verts = (0..5).map do |i|
      angle = Math::PI / 180 * (60 * i)
      [cx + HEX_SIZE * Math.cos(angle), cy + HEX_SIZE * Math.sin(angle)]
    end
    hex_edge_neighbours(ux, uy).each_with_index.filter_map do |neighbour, i|
      next if border_set.include?(neighbour)
      [verts[i], verts[(i + 1) % 6]]
    end
  end

  def star_fill_colour(colour_name)
    STAR_COLOURS[colour_name] || colour_name || '#FFD700'
  end
end
