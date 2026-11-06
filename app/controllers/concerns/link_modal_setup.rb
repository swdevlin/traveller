# frozen_string_literal: true

module LinkModalSetup
  extend ActiveSupport::Concern

  include HexViewport

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
    _viewport_parsecs, star_systems = build_hex_viewport(parsec, max_jump)

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

    build_survey_overlays_data

    @map_svg = render_to_string('shared/hex_map', formats: [:svg], layout: false)
  end
end
