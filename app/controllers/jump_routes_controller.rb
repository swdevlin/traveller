# frozen_string_literal: true

class JumpRoutesController < ApplicationController
  before_action :set_jump_route, except: %i[index new create]
  before_action :set_return_to, only: %i[edit update]

  def index
    @jump_routes = JumpRoute.ordered.includes(:jump_route_links)
  end

  def show
    if @jump_route.plotted?
      ActiveRecord::Associations::Preloader.new(
        records: [@jump_route],
        associations: { from_star_system: { parsec: :sector }, to_star_system: { parsec: :sector } }
      ).call

      timing        = RouteTiming.new(m_drive: @jump_route.m_drive || 1)
      @hop_timings  = timing.timings_for(@jump_route.ordered_systems)
      @route_total  = timing.total(@hop_timings)
    end
    @show_map = @jump_route.fits_in_sector?
    if @show_map
      prepare_route_map
      if @cols
        @show_map_links = true
        @map_svg = render_to_string('shared/hex_map', formats: [:svg], layout: false)
      end
    end
  end

  def new
    @jump_route = JumpRoute.new
  end

  def edit
    @travel_zones = TravelZone.ordered
    if @jump_route.plotted?
      ActiveRecord::Associations::Preloader.new(
        records: [@jump_route],
        associations: { from_star_system: { parsec: :sector }, to_star_system: { parsec: :sector } }
      ).call
    end
  end

  def create
    @jump_route = JumpRoute.new(jump_route_params)

    if @jump_route.save
      redirect_to @jump_route, notice: 'Jump route committed.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @jump_route.update(jump_route_params)
      if @jump_route.plotted? && @jump_route.from_star_system && @jump_route.to_star_system
        plan = @jump_route.recalculate_links!
        unless plan
          @travel_zones = TravelZone.ordered
          flash.now[:alert] = 'No valid route found with the current filters. Links unchanged.'
          render :edit, status: :unprocessable_entity and return
        end
      end
      redirect_to(@return_to == 'starmap' ? campaign_starmap_path : @jump_route,
                  notice: 'Jump route updated.', status: :see_other)
    else
      @travel_zones = TravelZone.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @jump_route.destroy!
    redirect_to jump_routes_path, notice: 'Jump route deleted.', status: :see_other
  end

  def map
    prepare_route_map
    return head :not_found unless @cols

    svg = render_to_string('shared/hex_map', formats: [:svg], layout: false)
    send_data svg, type: 'image/svg+xml', disposition: 'inline'
  end

  def export_path
    require 'csv'

    systems = @jump_route.ordered_systems

    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[name sector hex uwp]
      systems.each do |sys|
        csv << [
          sys.name,
          sys.parsec.sector.name,
          sys.parsec.hex_code,
          sys.main_world_uwp
        ]
      end
    end

    send_data csv_data,
              type: 'text/csv',
              disposition: "attachment; filename=\"#{@jump_route.name.parameterize}-path.csv\""
  end

  def export_links
    require 'csv'

    links = @jump_route.jump_route_links
      .includes(from_star_system: { parsec: :sector }, to_star_system: { parsec: :sector })
      .order(:id)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[from_system from_sector from_hex to_system to_sector to_hex]
      links.each do |link|
        csv << [
          link.from_star_system.name,
          link.from_star_system.parsec.sector.name,
          link.from_star_system.parsec.hex_code,
          link.to_star_system.name,
          link.to_star_system.parsec.sector.name,
          link.to_star_system.parsec.hex_code
        ]
      end
    end

    send_data csv_data,
              type: 'text/csv',
              disposition: "attachment; filename=\"#{@jump_route.name.parameterize}-links.csv\""
  end

  private

  def set_jump_route
    @jump_route = JumpRoute.find(params.expect(:id))
  end

  def set_return_to
    @return_to = 'starmap' if params[:return_to] == 'starmap'
  end

  def prepare_route_map
    links = @jump_route.jump_route_links.includes(
      :jump_route,
      from_star_system: :parsec,
      to_star_system: :parsec
    )
    return unless links.any?

    coords = links.flat_map { |l|
      [[l.from_star_system.parsec.x, l.from_star_system.parsec.y],
       [l.to_star_system.parsec.x,   l.to_star_system.parsec.y]]
    }
    xs = coords.map(&:first)
    ys = coords.map(&:last)
    min_x, max_x = xs.min, xs.max
    min_y, max_y = ys.min, ys.max

    return if (max_x - min_x + 1) > JumpRoute::SECTOR_COLS ||
              (max_y - min_y + 1) > JumpRoute::SECTOR_ROWS

    min_x -= 2; max_x += 2
    min_y -= 2; max_y += 2

    @ul   = Coordinate.new(min_x, max_y)
    @cols = max_x - min_x + 1
    @rows = max_y - min_y + 1

    parsec_rows = Parsec
      .where(x: min_x..max_x, y: min_y..max_y)
      .joins(:sector)
      .pluck('parsecs.id, parsecs.x, parsecs.y, parsecs.label, parsecs.label_colour, sectors.x, sectors.y')

    @parsecs_by_pos = parsec_rows.to_h do |pid, px, py, lbl, lc, sx, sy|
      col      = px - @ul.x + 1
      row      = @ul.y - py + 1
      hex_code = Parsec.hex_address_from_coords(px, py, sx, sy)
      [[col, row], { id: pid, hex_code: hex_code, label: lbl, label_colour: lc }]
    end

    star_systems = StarSystem
      .joins(:parsec)
      .where(parsecs: { x: min_x..max_x, y: min_y..max_y })
      .includes(:parsec, :allegiance, :main_world, stars: [:companion])

    @systems_by_pos = star_systems.each_with_object({}) do |sys, h|
      col = sys.parsec.x - @ul.x + 1
      row = @ul.y - sys.parsec.y + 1
      h[[col, row]] = sys
    end

    @jump_route_links_for_map = links
  end

  def jump_route_params
    params.expect(jump_route: [:name, :colour, :max_jump, :known, :notes, :line_style, :line_width,
                               :refueling, :from_star_system_id, :to_star_system_id,
                               excluded_travel_zone_ids: []])
  end
end
