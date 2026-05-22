# frozen_string_literal: true

class JumpRoutesController < ApplicationController
  before_action :set_jump_route, except: %i[index new create]

  def index
    @jump_routes = JumpRoute.ordered.includes(:jump_route_links)
  end

  def show
    @show_map = @jump_route.fits_in_sector?
  end

  def new
    @jump_route = JumpRoute.new
  end

  def edit
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
      redirect_to @jump_route, notice: 'Jump route updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @jump_route.destroy!
    redirect_to jump_routes_path, notice: 'Jump route deleted.', status: :see_other
  end

  def map
    links = @jump_route.jump_route_links.includes(
      :jump_route,
      from_star_system: :parsec,
      to_star_system: :parsec
    )

    return head :not_found unless links.any?

    coords = links.flat_map { |l|
      [[l.from_star_system.parsec.x, l.from_star_system.parsec.y],
       [l.to_star_system.parsec.x,   l.to_star_system.parsec.y]]
    }
    xs = coords.map(&:first)
    ys = coords.map(&:last)
    min_x, max_x = xs.min, xs.max
    min_y, max_y = ys.min, ys.max

    return head :not_found if (max_x - min_x + 1) > JumpRoute::SECTOR_COLS ||
                               (max_y - min_y + 1) > JumpRoute::SECTOR_ROWS

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

    svg = render_to_string('shared/hex_map', formats: [:svg], layout: false)
    send_data svg, type: 'image/svg+xml', disposition: 'inline'
  end

  def export_links
    require 'csv'

    links = @jump_route.jump_route_links
      .includes(from_star_system: :parsec, to_star_system: :parsec)
      .order(:id)

    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[from_system from_hex to_system to_hex]
      links.each do |link|
        csv << [
          link.from_star_system.name,
          link.from_star_system.parsec.hex_code,
          link.to_star_system.name,
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

  def jump_route_params
    params.expect(jump_route: [:name, :colour, :max_jump, :known, :notes, :line_style, :line_width])
  end
end
