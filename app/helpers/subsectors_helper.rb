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
    hex_map_svg_dimensions(8, 10)
  end

  def hex_map_svg_dimensions(cols, rows)
    width  = SVG_PADDING * 2 + cols * HEX_WIDTH * 0.75 + HEX_WIDTH * 0.25
    height = SVG_PADDING * 2 + rows * HEX_HEIGHT + HEX_HEIGHT * 0.5
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

  def regions_for_map(parsec_scope, ul, visible_col:, visible_row:, authenticated: true)
    region_scope = authenticated ? Region.all : Region.where(player_visible: true)

    fill_rows = region_scope
      .joins(region_parsecs: :parsec)
      .where(parsecs: { id: parsec_scope })
      .pluck('parsecs.x', 'parsecs.y', 'regions.colour')

    fills_by_pos = {}
    fill_rows.each do |px, py, colour|
      col = px - ul.x + 1
      row = ul.y - py + 1
      (fills_by_pos[[col, row]] ||= []) << { colour: colour }
    end

    label_rows = region_scope
      .where.not(label: [nil, ''])
      .where.not(label_x: nil)
      .joins(region_parsecs: :parsec)
      .where(parsecs: { id: parsec_scope })
      .distinct
      .pluck(:label, :label_x, :label_y, :colour, :label_colour)

    labels = label_rows.filter_map do |text, lx, ly, colour, label_colour|
      col = lx - ul.x + 1
      row = ul.y - ly + 1
      next unless visible_col.include?(col) && visible_row.include?(row)

      { col: col, row: row, text: text, colour: label_colour.presence || '#000000' }
    end

    border_rows = region_scope
      .where.not(border_colour: [nil, ''])
      .joins(region_parsecs: :parsec)
      .where(parsecs: { id: parsec_scope })
      .pluck('parsecs.x', 'parsecs.y', 'region_parsecs.kind', 'regions.border_colour', 'regions.id')

    region_borders = border_rows.group_by { |_, _, _, _, rid| rid }.map do |_rid, rows|
      colour = rows.first[3]
      border_parsecs = rows.filter_map { |px, py, kind, *| [px, py] if kind == 'border' }
      region_set = rows.map { |px, py, *| [px, py] }.to_set
      { colour: colour, parsecs: border_parsecs, region_set: region_set }
    end

    [fills_by_pos, labels, region_borders]
  end
end
