# frozen_string_literal: true

class JumpRoutesController < ApplicationController
  before_action :set_jump_route, except: %i[index new create]

  def index
    @jump_routes = JumpRoute.ordered.includes(:jump_route_links)
  end

  def show
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
