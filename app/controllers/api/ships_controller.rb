# frozen_string_literal: true

class Api::ShipsController < Api::BaseController
  def index
    ships = Ship.order(:name).to_a
    last_jumps = Ship.last_jumps_for(ships)
    render json: ships.map { |ship| ship_json(ship).merge(last_jump: last_jump_json(last_jumps[ship.id])) }
  end

  def show
    ship = Ship.find_by(id: params[:id])
    return render json: { error: 'ship not found' }, status: :not_found unless ship

    render json: ship_json(ship).merge(last_jump: last_jump_json(ship.last_jump))
  end

  private

  def ship_json(ship)
    { id: ship.id, name: ship.name, j_drive: ship.jump_drive, m_drive: ship.m_drive }
  end

  # The ship's most recent jump, both where it left and where it arrived, or
  # nil if it has not jumped.
  def last_jump_json(last)
    return unless last

    {
      from_parsec_id: last.from_parsec_id,
      from_sector_id: last.from_parsec.sector_id,
      to_parsec_id: last.to_parsec_id,
      to_sector_id: last.to_parsec.sector_id,
      from_star_system: star_system_json(last.from_parsec),
      to_star_system: star_system_json(last.to_parsec),
      depart_year: last.depart_year,
      depart_day: last.depart_day,
      arrive_year: last.arrive_year,
      arrive_day: last.arrive_day,
      misjump: last.misjump?
    }
  end

  # The system in a parsec, or nil: a ship can jump to a parsec with none.
  def star_system_json(parsec)
    system = parsec.star_systems.first
    { id: system.id, name: system.name } if system
  end
end
