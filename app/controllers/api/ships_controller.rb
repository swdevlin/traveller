# frozen_string_literal: true

class Api::ShipsController < Api::BaseController
  def index
    render json: Ship.order(:name).map { |ship| ship_json(ship) }
  end

  def show
    ship = Ship.find_by(id: params[:id])
    return render json: { error: 'ship not found' }, status: :not_found unless ship

    render json: ship_json(ship)
  end

  def last_jump
    ship = Ship.find_by(id: params[:id])
    return render json: { error: 'ship not found' }, status: :not_found unless ship

    last = JumpLog.includes(to_parsec: :sector)
                  .where(ship_id: ship.id)
                  .order(sequence: :desc, id: :desc)
                  .first

    if last&.to_parsec
      render json: {
        parsec_id: last.to_parsec_id,
        sector_id: last.to_parsec.sector_id,
        arrive_year: last.arrive_year,
        arrive_day: last.arrive_day
      }
    else
      render json: nil
    end
  end

  private

  def ship_json(ship)
    { id: ship.id, name: ship.name, jump_drive: ship.jump_drive, m_drive: ship.m_drive }
  end
end
