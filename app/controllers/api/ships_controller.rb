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

  # Where the ship last arrived, or nil if it has not jumped.
  def last_jump_json(last)
    return unless last&.to_parsec

    {
      parsec_id: last.to_parsec_id,
      sector_id: last.to_parsec.sector_id,
      arrive_year: last.arrive_year,
      arrive_day: last.arrive_day
    }
  end
end
