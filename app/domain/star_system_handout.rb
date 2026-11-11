# frozen_string_literal: true

require 'base64'

# Composes a one-page landscape handout for a star system as a list of HandoutCanvas primitives,
# for star_systems/handout.svg.erb to draw and SvgPdf to turn into a PDF.
#
# The handout is the main world profile plus a port briefing (the player notes), jump shadow
# times, starport charges and the commodity DMs for the system's trade codes. It is meant to be
# handed to players, so it never reads the referee notes or the extinct sophont.
#
# Text is monospaced throughout, so wrapping is exact without measuring glyphs. Anything that does
# not fit is cut down ("+ N more") and, failing that, left out and named in the footer.
class StarSystemHandout
  include JumpShadowMath
  include ActionView::Helpers::NumberHelper

  PAPER_SIZES = { 'letter' => [279.4, 215.9], 'a4' => [297.0, 210.0] }.freeze
  ADVISORY_LABEL = 'STARPORT CONTROL // PUBLIC ADVISORY'

  # The fixed colours; the accent and its tints come from the viewer's theme (HandoutPalette).
  BASE_COLOURS = { ink: '#1b2733', muted: '#5b6b7a', warn: '#b45f06' }.freeze

  Block = HandoutCanvas::Block

  MARGIN = 8.0
  COLUMN_GAP = 4.0
  SECTION_GAP = 2.5
  HEADING_HEIGHT = 5.5
  HEADER_HEIGHT = 21.0
  FOOTER_HEIGHT = 7.0
  MAX_MAP_PIXELS = 1800
  VALUE_SIZE = 2.0
  NOTES_SIZE = 2.2
  CAPITALS_SHOWN = 3
  MAX_NOTE_LINES = 7
  # The player notes are called Survey Records elsewhere in the app, which reads as map data on
  # paper, so the handouts title them as a port briefing.
  PLAYER_NOTES_TITLE = 'Port briefing'
  # Notes that are too long are shrunk (and their line spacing tightened) down to this size.
  NOTES_MIN_SIZE = 1.8
  # The schematic is for flavour, so it stays a short strip unless a side panel would show it
  # at least this many times larger.
  SIDE_PANEL_ADVANTAGE = 2.0
  MIN_ROWS_SHOWN = 2
  ROW_GAP = 0.3
  # Under the main world's node on the schematic: the layout puts its UWP this many units below
  # the node, and the year and day lines follow it at this size and spacing (mm).
  ROTATION_SUBLABEL_OFFSET = 18
  ROTATION_SIZE = 1.7
  UWP_SIZE = 5.0
  ZONE_TITLE_SIZE = 3.2
  ZONE_EYEBROW = 'TRAVEL ADVISORY'
  ZONE_EXTRA_HEIGHT = 3.5
  # Space between the zone's colour bar (1.2 mm wide) and its text.
  ZONE_BAR_GAP = 2.4
  ROTATION_LINE_HEIGHT = 2.4

  CODED_FIELDS = ['Starport', 'Population', 'Government', 'Law Level', 'Tech Level'].freeze

  CHARGE_FIELDS = [
    ['Berthing Cost', 'Berthing'], ['Refined Fuel Cost', 'Refined fuel'], ['Unrefined Fuel Cost', 'Unrefined fuel']
  ].freeze

  # Lets an ordinary markdown presenter hand back its tables as data instead of markdown lines.
  module SectionCapture
    def captured_sections
      @captured_sections ||= {}
    end

    private

    def table_section(title, rows)
      captured_sections[title] = rows
      []
    end

    def message_section(title, message)
      captured_sections[title] = message
      []
    end
  end

  attr_reader :width, :height, :omitted

  def initialize(star_system, campaign, theme: nil)
    @system = star_system
    @campaign = campaign
    @world = star_system.main_world
    @width, @height = PAPER_SIZES.fetch(campaign.handout_paper_size_or_default) { PAPER_SIZES.fetch('letter') }
    @colours = BASE_COLOURS.merge(HandoutPalette.for(theme))
    @omitted = []
  end

  def items
    @items ||= compose
  end

  def filename
    "#{@system.display_name.parameterize}-handout.pdf"
  end

  private

  def content_width
    @width - (2 * MARGIN)
  end

  def compose
    @items = []
    compose_header
    @area = compose_subway(MARGIN + header_height + SECTION_GAP)
    compose_player
    compose_footer
    @items
  end

  def area_x
    @area[:x]
  end

  def area_width
    @area[:width]
  end

  def area_top
    @area[:top]
  end

  # ---- page furniture ------------------------------------------------------------------------

  def compose_header
    right = @width - MARGIN
    name = @system.display_name.upcase
    name_size = [8.5, (content_width * 0.5) / (name.length * 0.85)].min

    @items << text(MARGIN, MARGIN + 2.4, "#{@campaign.name} // system survey record".upcase,
                   size: 2.0, fill: :accent, spacing: 0.3)
    @items << text(right, MARGIN + 2.4, ADVISORY_LABEL,
                   size: 2.0, fill: :warn, weight: 'bold', anchor: 'end', spacing: 0.3)
    @items << text(MARGIN, MARGIN + 12.0, name, size: name_size, font: :display, weight: 'bold')
    @items << text(MARGIN, MARGIN + 17.5, location_line, size: 2.4, fill: :muted)

    uwp = @system.main_world_uwp.presence
    if uwp
      @items << text(right, MARGIN + 7.5, 'MAIN WORLD UWP', size: 1.8, fill: :muted, anchor: 'end', spacing: 0.2)
      @items << text(right, MARGIN + 13.0, uwp, size: UWP_SIZE, font: :display, weight: 'bold', anchor: 'end')
    end
    compose_zone_banner(right)
    @items << rect(MARGIN, MARGIN + header_height - 1.0, content_width, 0.7, fill: :accent)
  end

  def location_line
    parsec = @system.parsec
    [
      parsec&.sector&.name,
      parsec&.hex_code && "Hex #{parsec.hex_code}",
      parsec&.subsector&.name&.then { |name| "#{name} subsector" }
    ].compact_blank.join(' · ')
  end

  # A travel advisory under the UWP at the right of the header, when the system has a travel zone: a
  # bar in the zone's own colour, a small "travel advisory" line and the zone name. The text uses a
  # darkened version of the colour, since amber and the like are too pale to read on white.
  def compose_zone_banner(right)
    zone = @system.travel_zone
    return unless zone

    ink = HandoutPalette.to_hex(HandoutPalette.readable_on_white(HandoutPalette.parse(zone.colour)))
    title = "#{zone.name} zone".upcase
    text_width = [title.length * ZONE_TITLE_SIZE * 0.7, ZONE_EYEBROW.length * 1.21].max

    @items << rect(right - text_width - ZONE_BAR_GAP - 1.2, MARGIN + 15.4, 1.2, 5.6, fill: zone.colour)
    @items << text(right, MARGIN + 17.2, ZONE_EYEBROW, size: 1.6, fill: ink, anchor: 'end', spacing: 0.25)
    @items << text(right, MARGIN + 20.6, title, size: ZONE_TITLE_SIZE, font: :display, weight: 'bold', fill: ink,
                                                anchor: 'end')
  end

  # The header grows a little to make room for the travel advisory.
  def header_height
    @system.travel_zone ? HEADER_HEIGHT + ZONE_EXTRA_HEIGHT : HEADER_HEIGHT
  end

  # The main world's year and day lengths, given equal weight, one to a line. They are drawn under
  # the world's own node on the schematic.
  def rotation_lines
    orbital = section_rows('Orbital Data')
    day = orbital['Sidereal Day'].presence || section_rows('Environmental Data')['Rotation']
    [
      ("Year #{orbital['Period']}" if orbital['Period'].present?),
      ("Day #{day}" if day.present?),
      ('Tidally locked' if orbital['Tidally Locked'].present?)
    ].compact
  end

  def main_world_node(layout)
    layout.nodes.find { |node| node.url_target == @world } if @world
  end

  # Text under the main world's node, placed by mapping the node's position in the layout's own
  # coordinates onto the page, the way the nested SVG will draw it (centred, aligned to the top).
  def rotation_items(layout, box, x, y, width, height)
    node = main_world_node(layout)
    lines = rotation_lines
    return [] if node.nil? || lines.empty?

    scale = [width / box[2], height / box[3]].min
    node_x = x + ((width - (box[2] * scale)) / 2) + ((node.x - box[0]) * scale)
    base = y + ((node.y - box[1] + node.radius + ROTATION_SUBLABEL_OFFSET) * scale)
    lines.each_with_index.map do |line, index|
      text(node_x, base + ((index + 1) * ROTATION_LINE_HEIGHT), line, size: ROTATION_SIZE, fill: :muted, anchor: 'middle')
    end
  end

  def compose_subway(top)
    layout = StarSystemMapLayout.new(@system)
    box = subway_view_box(layout)
    box_width = box[2]
    box_height = box[3]
    strip_limit = (page_bottom - top) * 0.17
    strip_height = (content_width * box_height / box_width).clamp(16.0, strip_limit)
    strip_scale = [content_width / box_width, strip_height / box_height].min

    side_limit = content_width * 0.36
    side_room = page_bottom - top - HEADING_HEIGHT - SECTION_GAP
    side_scale = [side_limit / box_width, side_room / box_height].min

    if side_scale > strip_scale * SIDE_PANEL_ADVANTAGE
      compose_side_subway(layout, box, top, side_scale, side_room)
    else
      compose_strip_subway(layout, box, top, strip_height)
    end
  end

  # The layout leaves a generous margin above and below the track; crop it to the content. The
  # allowances cover the labels drawn above (star names, AU) and below (UWP sublabels) the nodes.
  def subway_view_box(layout)
    return [0, 0, layout.svg_width, layout.svg_height] if layout.nodes.empty?

    top = [layout.nodes.map { |node| node.y - node.radius }.min - 32, 0].max
    bottom = layout.nodes.map { |node| node.y + node.radius }.max + 30
    # Room for the year and day lines under the main world's node.
    if (node = main_world_node(layout)) && rotation_lines.any?
      bottom = [bottom, node.y + node.radius + ROTATION_SUBLABEL_OFFSET + (rotation_lines.size * 26) + 4].max
    end
    bottom = [bottom, layout.svg_height].min
    [0, top, layout.svg_width, bottom - top]
  end

  def compose_strip_subway(layout, box, top, map_height)
    place(heading_items('Stellar system schematic', content_width, caption: 'Not to scale'), MARGIN, top)
    @items << HandoutCanvas::Subway.new(x: MARGIN, y: top + HEADING_HEIGHT, width: content_width,
                                        height: map_height, layout: layout, view_box: box)
    @items.concat(rotation_items(layout, box, MARGIN, top + HEADING_HEIGHT, content_width, map_height))
    { x: MARGIN, width: content_width, top: top + HEADING_HEIGHT + map_height + SECTION_GAP }
  end

  def compose_side_subway(layout, box, top, scale, room)
    panel_width = (box[2] * scale).clamp(55.0, content_width * 0.36)
    panel_height = [box[3] * scale, room].min
    x = @width - MARGIN - panel_width
    place(heading_items('System schematic', panel_width, caption: 'Not to scale'), x, top)
    @items << HandoutCanvas::Subway.new(x: x, y: top + HEADING_HEIGHT, width: panel_width,
                                        height: panel_height, layout: layout, view_box: box)
    @items.concat(rotation_items(layout, box, x, top + HEADING_HEIGHT, panel_width, panel_height))
    # Whatever is left below the map can hold more content.
    @spare = { x: x, width: panel_width, top: top + HEADING_HEIGHT + panel_height + SECTION_GAP }
    { x: MARGIN, width: content_width - panel_width - COLUMN_GAP, top: top }
  end

  def compose_footer
    base = @height - MARGIN
    @items << rect(MARGIN, base - 5.2, content_width, 0.2, fill: :rule)
    @items << text(MARGIN, base - 1.2, "#{@campaign.name} · stellar survey archive".upcase,
                   size: 1.8, fill: :muted, spacing: 0.2)
    @items << text(@width - MARGIN, base - 1.2, 'FIELD RECORD / 01 OF 01',
                   size: 1.8, fill: :muted, anchor: 'end', spacing: 0.2)
    return if @omitted.empty?

    @items << text(@width / 2, base - 1.2, "Omitted for space: #{@omitted.join(', ')}".upcase,
                   size: 1.6, fill: :warn, anchor: 'middle')
  end

  # ---- player layout -------------------------------------------------------------------------

  # Two columns. Left: the surface map, jump shadow and trade. Right: the profile, with the Survey
  # Records filling the rest of the column.
  def compose_player
    top = area_top
    bottom = page_bottom
    left_width = area_width * 0.42
    right_width = area_width - left_width - COLUMN_GAP
    right_x = area_x + left_width + COLUMN_GAP

    unless @world
      block = no_world_block(area_width)
      place(block.items, area_x, top)
      return place_player_notes(area_x, top + block.height, area_width, bottom)
    end

    compose_player_left(area_x, left_width, top, bottom)

    profile = profile_section(right_width)
    place(profile.items, right_x, top) if profile
    place_player_notes(right_x, top + (profile&.height || 0), right_width, bottom)
  end

  def compose_player_left(x, width, top, bottom)
    jump = jump_section(width)
    trade = trade_block_for_player(width, bottom - top - (jump&.height || 0))
    map = map_section(width, bottom - top - (jump&.height || 0) - (trade&.height || 0))
    y = top
    [map, jump, trade].compact.each do |block|
      place(block.items, x, y)
      y += block.height
    end
    @omitted << 'Trade & commerce' if trade.nil? && @system.trade_dm_codes.any?
  end

  # Trade goes under the jump shadow, taking at most 45% of the column so that the map keeps room.
  def trade_block_for_player(width, column_room)
    return unless @system.trade_dm_codes.any?

    trade_section(width, [column_room * 0.45, trade_section(width, nil)&.height.to_f].min)
  end

  def place_player_notes(x, top, width, bottom)
    markdown = notes_markdown
    return if markdown.blank? || bottom - top < HEADING_HEIGHT + 8.0

    block = notes_section(PLAYER_NOTES_TITLE, markdown, width, bottom - top, :accent)
    place(block.items, x, top)
  end

  # The main world's profile as a grid of cells, with the UWP in its standard order (starport, size,
  # atmosphere, hydrographics, population, government, law level, tech level). Cells with a UWP code
  # show it beside the label. Starport carries its charges, population its native sophont (if any) and
  # atmosphere the temperature and survival requirement as notes under the value.
  def profile_section(width)
    profile = profile_rows.to_h
    cells = [
      starport_cell(profile),
      size_cell(profile),
      atmosphere_cell(profile),
      hydrographics_cell('Hydrographics', profile['Hydrographics Liquid']),
      with_note(population_cell(profile), population_notes(profile)),
      coded_cell('Government', 'Government', profile['Government']),
      coded_cell('Law Level', 'Law level', profile['Law Level']),
      coded_cell('Tech Level', 'Tech level', profile['Tech Level'])
    ].compact
    return if cells.empty?

    section('Planetary profile', width, kv_cells(cells, width, count: 3),
            caption: "Main world · #{@world.display_name}")
  end

  # Cells are [label, value, code, note]; a note is a string or an array of lines.
  def with_note(cell, note)
    return unless cell

    [cell[0], cell[1], cell[2], note]
  end

  def section_rows(title)
    rows = world_sections[title]
    rows.is_a?(Array) ? rows.to_h : {}
  end

  # "5 — 10,356 km" in the Physical Data section: the size code, with the diameter and gravity.
  def size_cell(profile)
    code, diameter = section_rows('Physical Data')['Diameter'].to_s.split(' — ', 2)
    description = [labelled('Diameter', diameter), labelled('Gravity', profile['Gravity'])].compact
    return if description.empty?

    uwp_code?(code) ? ['Size', description, code] : ['Size', description]
  end

  # "8 — Dense": the atmosphere code and description, with what is needed to survive in it.
  def atmosphere_cell(profile)
    code, description = section_rows('Atmosphere')['Atmosphere'].to_s.split(' — ', 2)
    description = profile['Atmosphere'] if description.blank?
    return if description.blank?

    notes = [labelled('Temperature', profile['Temperature']), survival_note(profile['Survival Req.'])].compact_blank
    ['Atmosphere', description, (code if uwp_code?(code)), notes.presence]
  end

  # "Gravity: 0.9 g", so that a bare figure is never left without saying what it is.
  def labelled(label, value)
    "#{label}: #{value}" if value.present?
  end

  # "None" in the survival requirement means no special gear is needed, which "Survival: None"
  # would read as the opposite.
  def survival_note(requirement)
    case requirement
    when nil, '' then nil
    when 'None' then 'No special gear required'
    when 'Varies' then 'Gear required varies'
    when 'Not Survivable' then 'Not survivable'
    else "Requires #{requirement.gsub(' + ', ' and ')}"
    end
  end

  def uwp_code?(code)
    code.to_s.match?(/\A[0-9A-Z]{1,2}\z/)
  end

  # The population as a short figure ("15.5 billion"), when the census figure is known.
  def population_cell(profile)
    cell = coded_cell('Population', 'Population', profile['Population'])
    census = @world.try(:census_population)
    cell[1] = abbreviate_number(census) if cell && census.present?
    cell
  end

  # The native sophont, if any, then the principal (largest) city and the capital cities.
  def population_notes(profile)
    [sophont_note(profile), *city_notes].compact.presence
  end

  def city_notes
    return [] unless @world.respond_to?(:cities)

    largest = @world.cities.largest_first.first
    return [] unless largest

    designation = largest.capital_label && " (#{largest.capital_label.downcase})"
    notes = ["Principal city: #{city_line(largest)}#{designation}"]
    capitals = @world.cities.capitals.largest_first.where.not(id: largest.id).to_a
                     .sort_by { |city| [City::CAPITAL_DESIGNATIONS.keys.index(city.capital_designation), -city.population] }
    notes.concat(capitals.first(CAPITALS_SHOWN).map { |city| "#{city.capital_label}: #{city_line(city)}" })
    notes << "+ #{capitals.size - CAPITALS_SHOWN} more capitals" if capitals.size > CAPITALS_SHOWN
    notes
  end

  # Compact figures keep a city on one line in the narrow cell: "Gir Gust 891M".
  def city_line(city)
    "#{city.name.presence || 'Unnamed city'} #{abbreviate_number(city.population, compact: true)}"
  end

  # 1,986,066,666 as "1.99 billion" (or "1.99B"); 3,300,000 as "3.3 million" (or "3.3M").
  def abbreviate_number(number, compact: false)
    units = compact ? { thousand: 'K', million: 'M', billion: 'B', trillion: 'T' } : { thousand: 'thousand', million: 'million', billion: 'billion', trillion: 'trillion' }
    number_to_human(number, units: units, format: compact ? '%n%u' : '%n %u',
                            precision: 3, significant: true, strip_insignificant_zeros: true)
  end

  # The starport with its charges and the bases at it. A system with bases but no starport data gets
  # a cell of its own for them.
  def starport_cell(profile)
    notes = [*charges_note(profile), bases_note].compact.presence
    cell = coded_cell('Starport', 'Starport', profile['Starport'])
    return with_note(cell, notes) if cell

    ['Bases', bases_note.delete_prefix('Bases: ')] if bases_note
  end

  def bases_note
    names = @system.facilities.order(:code).map { |facility| facility.name.presence || facility.code }
    "Bases: #{names.join(', ')}" if names.any?
  end

  # "Berthing Cr10" and "Fuel cost: - / Cr100" (refined / unrefined), with a hyphen where a charge is
  # not available.
  def charges_note(profile)
    return unless CHARGE_FIELDS.any? { |key, _label| profile.key?(key) }

    berthing, refined, unrefined = CHARGE_FIELDS.map { |key, _label| charge_figure(profile[key]) }
    ["Berthing #{berthing}", "Fuel cost: #{refined} / #{unrefined}"]
  end

  def charge_figure(value)
    value.blank? || value == '—' ? '-' : value
  end

  def sophont_note(profile)
    sophont = profile['Native Sophont']
    "Native sophont: #{sophont}" if sophont.present? && sophont != 'None'
  end

  # Starport, population, government, law level and tech level are UWP codes, so their code is pulled out of
  # the value ("7 — 10,000,000 – 99,999,999") and set beside the label, as "POPULATION / 7".
  def coded_cell(key, label, value)
    return if value.blank?
    return [label, value] unless CODED_FIELDS.include?(key)

    code, description = value.split(' — ', 2)
    uwp_code?(code) && description.present? ? [label, description, code] : [label, value]
  end

  # The hydrographics code with its coverage and liquid: "HYDROGRAPHICS / 3", "28% · Water".
  def hydrographics_cell(label, liquid)
    code, coverage = world_sections['Hydrographics']&.first&.last.to_s.split(' — ', 2)
    description = [coverage, liquid].compact_blank.join(' · ')
    return if description.blank?

    uwp_code?(code) ? [label, description, code] : [label, description]
  end

  def profile_rows
    rows = world_sections['Planetary Profile']
    rows.is_a?(Array) ? rows : []
  end

  def no_world_block(width)
    section('Main world', width, paragraph_block('No main world has been designated for this system.', width))
  end

  def map_section(width, max_height)
    content_height = max_height - HEADING_HEIGHT - SECTION_GAP
    return if content_height < 15

    image = map_image
    content = if image
                href, aspect = image
                image_width = width
                image_height = image_width / aspect
                if image_height > content_height
                  image_height = content_height
                  image_width = image_height * aspect
                end
                x = (width - image_width) / 2
                Block.new([HandoutCanvas::Image.new(x: x, y: 0, width: image_width, height: image_height, href: href)],
                          image_height)
    else
                placeholder_height = [content_height, 30.0].min
                Block.new([
                            rect(0, 0, width, placeholder_height, fill: :tint),
                            text(width / 2, (placeholder_height / 2) + 1, 'NO SURFACE MAP ON FILE',
                                 size: 2.2, fill: :muted, anchor: 'middle', spacing: 0.2)
                          ], placeholder_height)
    end
    section('Planetary cartography', width, content, caption: "#{@world.display_name} · surface map")
  end

  # The map is converted to PNG at a sensible size: it keeps the PDF small and does not depend on
  # librsvg being able to read WebP. Returns [data URI, aspect ratio], or nil if there is no map.
  def map_image
    return @map_image if defined?(@map_image)

    @map_image = build_map_image
  end

  def build_map_image
    map = @world.try(:planet_map)
    return unless map&.webp&.attached?

    image = Vips::Image.new_from_buffer(map.webp_data, '')
    image = image.thumbnail_image(MAX_MAP_PIXELS, size: :down) if image.width > MAX_MAP_PIXELS
    ["data:image/png;base64,#{Base64.strict_encode64(image.pngsave_buffer)}", image.width.to_f / image.height]
  rescue Vips::Error => e
    Rails.logger.warn("Handout map for #{@world.id} could not be read: #{e.message}")
    nil
  end

  def jump_distance
    distance = @world&.effective_jump_shadow_km
    distance if distance&.positive?
  end

  def jump_section(width)
    distance = jump_distance
    return unless distance

    cell_width = width / 6
    items = jump_shadow_travel_times(distance).each_with_index.flat_map do |(g, time), index|
      x = index * cell_width
      [
        text(x, 2.2, "#{g}G", size: 1.8, fill: :muted),
        text(x, 6.0, time, size: 2.8, font: :display, weight: 'bold')
      ]
    end
    source = @world.effective_jump_shadow_source
    section('Jump shadow', width, Block.new(items, 7.5), caption: source && "Source: #{source.display_name}")
  end

  # The main world's trade codes, then the purchase and sale DMs they give for each good.
  def trade_section(width, max_height)
    inner = max_height && (max_height - HEADING_HEIGHT - SECTION_GAP)
    return if inner && inner < 14

    codes = @system.trade_codes.order(:code).map { |code| [code.code, code.definition] }
    parts = []
    parts << trade_codes_block(codes, width) if codes.any?
    used = parts.sum(&:height) + (parts.any? ? 2.0 : 0)
    goods = dm_block(TradeGoodsTable.dms_for(@system.trade_dm_codes), width, inner && (inner - used))
    return unless goods

    parts << goods
    section('Trade & commerce', width, stack(parts, gap: 2.0), caption: 'Purchase & sale DMs')
  end

  # The trade codes with their meanings, each code in bold accent colour like the UWP codes, a
  # code and its meaning kept together and wrapped from one to the next.
  def trade_codes_block(codes, width, size: VALUE_SIZE)
    char = char_width(size)
    max_chars = columns(width, size)
    items = []
    line = 0
    used = 0
    codes.each do |code, definition|
      length = code.length + 1 + definition.to_s.length
      if used.positive? && used + 3 + length > max_chars
        line += 1
        used = 0
      end
      baseline = (line * line_height(size)) + size
      if used.positive?
        items << text((used + 1) * char, baseline, '·', size: size, fill: :muted)
        used += 3
      end
      items << text(used * char, baseline, code, size: size, fill: :accent, weight: 'bold')
      items << text((used + code.length + 1) * char, baseline, truncate_plain(definition, max_chars - code.length - 1), size: size)
      used += length
    end
    Block.new(items, (line + 1) * line_height(size))
  end

  # The goods listed in two or three side-by-side runs, as many as fit; the rest are summarised.
  def dm_block(goods, width, max_height)
    line_height = 3.0
    if goods.empty?
      return Block.new([text(0, VALUE_SIZE, 'No commodity DMs for these codes.', size: VALUE_SIZE, fill: :muted)], 3.0)
    end

    ups = width >= 130 ? 3 : 2
    balanced = (goods.size.to_f / ups).ceil
    per_column = max_height ? [((max_height - 4.0) / line_height).floor, balanced].min : balanced
    return if per_column < MIN_ROWS_SHOWN

    capacity = per_column * ups
    shown = goods.size > capacity ? goods.first(capacity - 1) : goods
    extra = goods.size - shown.size
    run_width = (width - (COLUMN_GAP * (ups - 1))) / ups
    name_cols = ((run_width - 12.0) / char_width(VALUE_SIZE)).floor

    items = []
    ups.times do |run|
      x = run * (run_width + COLUMN_GAP)
      items << text(x, 2.0, 'COMMODITY', size: 1.7, fill: :muted, weight: 'bold')
      items << text(x + run_width - 6.5, 2.0, 'BUY', size: 1.7, fill: :muted, weight: 'bold', anchor: 'end')
      items << text(x + run_width, 2.0, 'SELL', size: 1.7, fill: :muted, weight: 'bold', anchor: 'end')
    end
    shown.each_with_index do |good, index|
      x = (index / per_column) * (run_width + COLUMN_GAP)
      baseline = 4.0 + ((index % per_column) * line_height) + VALUE_SIZE
      items << text(x, baseline, truncate_plain(good[:name], name_cols), size: VALUE_SIZE)
      items << text(x + run_width - 6.5, baseline, format_dm(good[:purchase_dm]), size: VALUE_SIZE, anchor: 'end')
      items << text(x + run_width, baseline, format_dm(good[:sale_dm]), size: VALUE_SIZE, anchor: 'end')
    end
    slots = shown.size + (extra.positive? ? 1 : 0)
    if extra.positive?
      x = (shown.size / per_column) * (run_width + COLUMN_GAP)
      baseline = 4.0 + ((shown.size % per_column) * line_height) + VALUE_SIZE
      items << text(x, baseline, "+ #{extra} more", size: VALUE_SIZE, fill: :muted, italic: true)
    end
    Block.new(items, 4.0 + ([slots, per_column].min * line_height))
  end

  def format_dm(value)
    value.zero? ? '—' : format('%+d', value)
  end

  # ---- notes ---------------------------------------------------------------------------------

  def page_bottom
    @height - MARGIN - FOOTER_HEIGHT
  end

  # The port briefing is the player notes of the system and its main world. The system's notes come
  # first, unheaded. The main world's follow them under its name only when both have notes, to tell
  # the two apart.
  def notes_markdown
    system_notes = @system.player_notes.to_s.strip
    world_notes = @world&.player_notes.to_s.strip
    world_notes = "**#{@world.display_name}**\n\n#{world_notes}" if world_notes.present? && system_notes.present?
    [system_notes, world_notes].compact_blank.join("\n\n")
  end

  def notes_section(title, markdown, width, max_height, colour)
    layout = SvgMarkdownLayout.fit(markdown, width: width, max_height: max_height - HEADING_HEIGHT,
                                             size: NOTES_SIZE, min_size: NOTES_MIN_SIZE)
    items = heading_items(title, width, fill: colour)
    items.concat(markdown_items(layout).map { |item| item.translate(0, HEADING_HEIGHT) })
    Block.new(items, HEADING_HEIGHT + layout.height)
  end

  def markdown_items(layout)
    rects = layout.rects.map do |r|
      fill = { code: :code, box: :tint, quote: :accent, rule: :rule }.fetch(r.kind)
      rect(r.x, r.y, r.width, r.height, fill: fill)
    end
    texts = layout.texts.map do |t|
      text(t.x, t.y, t.text, size: t.size, weight: t.style[:bold] ? 'bold' : nil, italic: t.style[:italic],
                             strike: t.style[:strike], underline: t.style[:underline])
    end
    rects + texts
  end

  # ---- main world data -----------------------------------------------------------------------

  def world_sections
    @world_sections ||= build_world_sections
  end

  def build_world_sections
    return {} unless @world

    presenter = StellarObjectMarkdownPresenter.for(@world, @campaign)
    presenter.extend(SectionCapture)
    presenter.send(:planetary_profile_summary) if presenter.respond_to?(:planetary_profile_summary, true)
    presenter.send(:type_sections)
    presenter.captured_sections
  end

  # ---- block building ------------------------------------------------------------------------

  def heading_items(title, width, caption: nil, fill: :accent)
    items = [text(0, 2.4, title.upcase, size: 2.0, fill: fill, weight: 'bold', spacing: 0.3)]
    items << text(width, 2.4, caption.upcase, size: 1.7, fill: :muted, anchor: 'end') if caption
    items << rect(0, 3.6, width, 0.25, fill: :rule)
    items
  end

  def section(title, width, content, caption: nil)
    items = heading_items(title, width, caption: caption)
    items.concat(content.translated(0, HEADING_HEIGHT))
    Block.new(items, HEADING_HEIGHT + content.height + SECTION_GAP)
  end

  def stack(blocks, gap: 0.0)
    y = 0.0
    items = []
    blocks.each do |block|
      items.concat(block.translated(0, y))
      y += block.height + gap
    end
    Block.new(items, [y - gap, 0.0].max)
  end

  def paragraph_block(string, width, size: VALUE_SIZE)
    lines = wrap_plain(string, columns(width, size))
    items = lines.each_with_index.map { |line, index| text(0, (index * line_height(size)) + size, line, size: size) }
    Block.new(items, lines.size * line_height(size))
  end

  # A grid of small labelled values: label above (with the code, if any, beside it), the value
  # (a string, or an array of lines; up to three lines in all) below, and then an optional smaller note. Cells are [label, value, code, note].
  def kv_cells(cells, width, count:, label_size: 1.8, value_size: 2.5, note_size: 1.9)
    gap = 3.0
    height = line_height(value_size)
    note_height = line_height(note_size)
    label_step = (label_size * SvgMarkdownLayout::CHAR_RATIO) + 0.15
    items = []
    y = 0.0
    cells.each_slice(count) do |row|
      # A short last row shares the full width between its cells rather than leaving it empty.
      cell_width = (width - (gap * (row.size - 1))) / row.size
      value_columns = columns(cell_width, value_size)
      note_columns = columns(cell_width, note_size)
      wrapped = row.map { |_label, value| Array(value).flat_map { |line| wrap_plain(line, value_columns) }.first(3) }
      notes = row.map { |_label, _value, _code, note| Array(note).flat_map { |line| wrap_plain(line, note_columns) }.first(MAX_NOTE_LINES) }
      row.each_with_index do |(label, _value, code), index|
        x = index * (cell_width + gap)
        items << text(x, y + label_size, label.upcase, size: label_size, fill: :muted, spacing: 0.15)
        if code
          items << text(x + ((label.length + 1) * label_step), y + label_size, '/', size: label_size, fill: :muted)
          items << text(x + ((label.length + 3) * label_step), y + label_size, code,
                        size: label_size * 1.25, fill: :accent, weight: 'bold')
        end
        wrapped[index].each_with_index do |line, i|
          items << text(x, y + 3.4 + value_size + (i * height), line, size: value_size)
        end
        notes[index].each_with_index do |line, i|
          items << text(x, y + 3.4 + (wrapped[index].size * height) + 0.4 + note_size + (i * note_height), line,
                        size: note_size, fill: :muted)
        end
      end
      content = row.each_index.map do |i|
        (wrapped[i].size * height) + (notes[i].any? ? 0.4 + (notes[i].size * note_height) : 0)
      end
      y += 3.4 + content.max + 1.6
      items << rect(0, y - 0.9, width, 0.15, fill: :rule)
    end
    Block.new(items, y)
  end

  # ---- primitives and text helpers -------------------------------------------------------------

  def place(items, x, y)
    @items.concat(items.map { |item| item.translate(x, y) })
  end

  def text(x, y, string, size: 2.3, font: :mono, fill: :ink, weight: nil, italic: false, strike: false,
           underline: false, anchor: 'start', spacing: nil)
    HandoutCanvas::Text.new(x: x, y: y, size: size, text: string.to_s, font: font, fill: colour_for(fill),
                            weight: weight, italic: italic, strike: strike, underline: underline,
                            anchor: anchor, spacing: spacing)
  end

  def rect(x, y, width, height, fill: nil, stroke: nil, stroke_width: nil)
    HandoutCanvas::Rect.new(x: x, y: y, width: width, height: height, fill: fill && colour_for(fill),
                            stroke: stroke && @colours.fetch(stroke), stroke_width: stroke_width)
  end

  # A theme colour name, or a hex colour used as it is.
  def colour_for(colour)
    colour.is_a?(String) ? colour : @colours.fetch(colour)
  end

  def char_width(size)
    size * SvgMarkdownLayout::CHAR_RATIO
  end

  def line_height(size)
    size * 1.35
  end

  def columns(width, size)
    [(width / char_width(size)).floor, 1].max
  end

  def truncate_plain(string, columns)
    string = string.to_s
    string.length > columns ? "#{string[0, [columns - 1, 0].max]}…" : string
  end

  # Greedy word wrap for plain text; words longer than a line are split.
  def wrap_plain(string, columns)
    lines = []
    current = ''
    string.to_s.split.each do |word|
      while word.length > columns
        if current.empty?
          lines << word[0, columns]
          word = word[columns..]
        else
          lines << current
          current = ''
        end
      end
      if current.empty?
        current = word
      elsif current.length + 1 + word.length <= columns
        current += " #{word}"
      else
        lines << current
        current = word
      end
    end
    lines << current unless current.empty?
    lines.empty? ? [''] : lines
  end
end
