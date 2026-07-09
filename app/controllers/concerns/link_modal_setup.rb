# frozen_string_literal: true

module LinkModalSetup
  extend ActiveSupport::Concern

  private

  def setup_link_modal_ivars
    @jump_routes = JumpRoute.ordered
    @selected_jump_route = if params[:jump_route_id].present?
                             JumpRoute.find_by(id: params[:jump_route_id])
    else
                             @jump_routes.first
    end

    parsec = @star_system.parsec
    max_jump = @max_jump = @selected_jump_route&.max_jump || 3

    ulx = parsec.x - max_jump
    ulx -= 1 if ulx.odd?
    uly = parsec.y + max_jump

    @cols = parsec.x + max_jump - ulx + 1
    @rows = max_jump * 2 + 1
    @ul = Coordinate.new(ulx, uly)
    @highlight_pos = [parsec.x - ulx + 1, max_jump + 1]
    @jump_highlight_positions = Set.new

    viewport_parsecs = Parsec.includes(:sector)
                             .where(x: ulx..(ulx + @cols - 1), y: (uly - @rows + 1)..uly)
                             .load

    viewport_parsec_ids = viewport_parsecs.map(&:id)

    star_systems = StarSystem.where(parsec_id: viewport_parsec_ids)
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

    @region_fills_by_pos, @region_labels, @region_borders = helpers.regions_for_map(
      viewport_parsecs, @ul,
      visible_col: 1..@cols, visible_row: 1..@rows,
      authenticated: true
    )

    viewport_system_ids = star_systems.map(&:id)

    all_viewport_links = if @selected_jump_route && viewport_system_ids.any?
                           JumpRouteLink.where(jump_route: @selected_jump_route)
                             .where('from_star_system_id IN (?) OR to_star_system_id IN (?)', viewport_system_ids, viewport_system_ids)
                             .includes(:jump_route, from_star_system: :parsec, to_star_system: :parsec)
                             .to_a
    else
                           []
    end

    @jump_route_links_for_map = all_viewport_links
    my_links = all_viewport_links
                 .select { |l| l.from_star_system_id == @star_system.id || l.to_star_system_id == @star_system.id }
    @linked_system_ids = my_links
                           .flat_map { |l| [l.from_star_system_id, l.to_star_system_id] }
                           .reject { |id| id == @star_system.id }
                           .to_set
    @linked_system_links = my_links.each_with_object({}) do |l, h|
      other_id = l.from_star_system_id == @star_system.id ? l.to_star_system_id : l.from_star_system_id
      h[other_id] = l
    end

    @hex_click_map = {}
    if @selected_jump_route
      @systems_by_pos.each do |(col, row), sys|
        next if sys.id == @star_system.id
        next if @linked_system_ids.include?(sys.id)
        @hex_click_map[[col, row]] = quick_link_star_system_path(
          @star_system,
          jump_route_id: @selected_jump_route.id,
          to_system_id: sys.id
        )
      end
    end

    nearby_parsec_id_set = Parsec.where(
      'GREATEST(ABS(q - ?), ABS(r - ?), ABS(s - ?)) <= ? AND id != ?',
      parsec.q, parsec.r, parsec.s, max_jump, parsec.id
    ).pluck(:id).to_set

    @nearby_systems = star_systems
      .select { |s| nearby_parsec_id_set.include?(s.parsec_id) }
      .sort_by { |s| [s.parsec.q - parsec.q, s.parsec.r - parsec.r, s.parsec.s - parsec.s].map(&:abs).max }

    @map_svg = render_to_string('shared/hex_map', formats: [:svg], layout: false)
  end
end
