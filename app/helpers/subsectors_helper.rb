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

  # Edge-to-centre hex fade: mirrors the Elm starmap's `fadeGradients` radial
  # gradient (offset% => amount mixed toward the hex's own colour), reaching the
  # supplied colour in full at the hex edge. Region fills are excluded from this
  # everywhere it's used — they stay solid.
  HEX_FADE_DEFAULT_BG = '#ffffff'
  HEX_FADE_STOPS = [[0, 0.07], [35, 0.10], [55, 0.33], [75, 0.67], [100, 1.0]].freeze

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

  def effective_hex_size
    @hex_size || current_campaign&.hex_size_value || HEX_SIZE
  end

  def hex_map_svg_dimensions(cols, rows)
    hs = effective_hex_size
    hh = hs * Math.sqrt(3)
    hw = hs * 2
    width  = SVG_PADDING * 2 + cols * hw * 0.75 + hw * 0.25
    height = SVG_PADDING * 2 + rows * hh + hh * 0.5
    [width.round, height.round]
  end

  def hex_center(col, row)
    hs = effective_hex_size
    hh = hs * Math.sqrt(3)
    hw = hs * 2
    c = col - 1
    r = row - 1
    y_offset = col.even? ? hh * 0.5 : 0

    cx = SVG_PADDING + c * hw * 0.75 + hw / 2
    cy = SVG_PADDING + r * hh + y_offset + hh / 2
    [cx, cy]
  end

  def hex_polygon_points(cx, cy, size = nil)
    size ||= effective_hex_size
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
    hs = effective_hex_size
    cx, cy = hex_center(col, row)
    verts = (0..5).map do |i|
      angle = Math::PI / 180 * (60 * i)
      [cx + hs * Math.cos(angle), cy + hs * Math.sin(angle)]
    end
    hex_edge_neighbours(ux, uy).each_with_index.filter_map do |neighbour, i|
      next if border_set.include?(neighbour)
      [verts[i], verts[(i + 1) % 6]]
    end
  end

  def star_fill_colour(colour_name)
    STAR_COLOURS[colour_name] || colour_name || '#FFD700'
  end

  def hex_fade_gradient_id(colour)
    "hex-fade-#{colour.to_s.gsub(/[^0-9a-zA-Z]/, '')}"
  end

  # [[offset_percent, mixed_hex_colour], ...] for a `<radialGradient>`'s `<stop>`s.
  def hex_fade_stops(colour)
    HEX_FADE_STOPS.map { |offset, amount| [offset, mix_hex(HEX_FADE_DEFAULT_BG, colour, amount)] }
  end

  def mix_hex(from_hex, to_hex, amount)
    from_rgb = hex_to_rgb(from_hex)
    to_rgb = hex_to_rgb(to_hex)
    mixed = from_rgb.zip(to_rgb).map { |f, t| (f + (t - f) * amount).round.clamp(0, 255) }
    format('#%02x%02x%02x', *mixed)
  end

  def hex_to_rgb(hex)
    digits = hex.to_s.delete('#')
    digits = digits.chars.map { |c| c * 2 }.join if digits.length == 3
    [digits[0..1], digits[2..3], digits[4..5]].map { |h| h.to_i(16) }
  end

  def regions_for_map(parsec_scope, ul, visible_col:, visible_row:, authenticated: true)
    region_scope = authenticated ? Region.all : Region.where(player_visible: true)

    fill_rows = region_scope
      .where.not(colour: [nil, ''])
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
