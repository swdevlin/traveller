# frozen_string_literal: true

# Builds the ivars shared/hex_map.svg.erb needs to draw a hex map centred on a parsec:
# the viewport geometry, the parsecs and star systems in it, and region overlays.
module HexViewport
  extend ActiveSupport::Concern

  include HexMapOverlays

  private

  # Returns [viewport_parsecs, star_systems].
  def build_hex_viewport(parsec, radius)
    ulx = parsec.x - radius
    ulx -= 1 if ulx.odd?
    uly = parsec.y + radius

    @cols = parsec.x + radius - ulx + 1
    @rows = radius * 2 + 1
    @ul = Coordinate.new(ulx, uly)
    @highlight_pos = [parsec.x - ulx + 1, radius + 1]
    @jump_highlight_positions = Set.new

    viewport_parsecs = Parsec.includes(:sector)
                             .where(x: ulx..(ulx + @cols - 1), y: (uly - @rows + 1)..uly)
                             .load

    star_systems = StarSystem.where(parsec_id: viewport_parsecs.map(&:id))
                             .includes({ parsec: { sector: :subsectors } }, :allegiance, :travel_zone, stars: [], main_world: :trade_codes)
                             .load

    systems_by_parsec_id = star_systems.index_by(&:parsec_id)

    @parsecs_by_pos = {}
    @systems_by_pos = {}

    viewport_parsecs.each do |p|
      col = p.x - ulx + 1
      row = uly - p.y + 1
      @parsecs_by_pos[[col, row]] = { id: p.id, hex_code: p.hex_code, label: p.label, label_colour: p.label_colour }
      sys = systems_by_parsec_id[p.id]
      @systems_by_pos[[col, row]] = sys if sys
    end

    @region_fills_by_pos, @region_labels, @region_borders = helpers.regions_for_map(
      viewport_parsecs, @ul,
      visible_col: 1..@cols, visible_row: 1..@rows,
      authenticated: true
    )

    [viewport_parsecs, star_systems]
  end
end
