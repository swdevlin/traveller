# frozen_string_literal: true

# Renders a compact hex map spanning two star systems (e.g. an origin and
# destination for a traffic calculator), with both highlighted. Skipped
# (leaves @map_svg nil) when they're too far apart to show usefully on one map.
module TwoSystemMapBuildable
  extend ActiveSupport::Concern

  MAP_MARGIN   = 2
  MAP_MAX_SPAN = 30

  private

  def build_two_system_map_svg(from_parsec, to_parsec)
    min_x = [from_parsec.x, to_parsec.x].min - MAP_MARGIN
    max_x = [from_parsec.x, to_parsec.x].max + MAP_MARGIN
    min_y = [from_parsec.y, to_parsec.y].min - MAP_MARGIN
    max_y = [from_parsec.y, to_parsec.y].max + MAP_MARGIN

    ulx = min_x
    ulx -= 1 if ulx.odd? # hex_center offsets even grid cols; ulx must be even so parity matches universal-x
    uly = max_y

    @cols = max_x - ulx + 1
    @rows = uly - min_y + 1
    return if @cols > MAP_MAX_SPAN || @rows > MAP_MAX_SPAN

    @ul = Coordinate.new(ulx, uly)
    @jump_highlight_positions = Set[
      [from_parsec.x - ulx + 1, uly - from_parsec.y + 1],
      [to_parsec.x - ulx + 1, uly - to_parsec.y + 1]
    ]

    viewport_parsecs = Parsec.includes(:sector)
                             .where(x: ulx..(ulx + @cols - 1), y: (uly - @rows + 1)..uly)
                             .load

    star_systems = StarSystem.where(parsec_id: viewport_parsecs.map(&:id))
                             .includes(:parsec, :allegiance, :travel_zone, stars: [])
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

    @map_svg = render_to_string('shared/hex_map', formats: [:svg], layout: false)
  end
end
