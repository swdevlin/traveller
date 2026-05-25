# frozen_string_literal: true

class Api::ShipsController < Api::BaseController
  def index
    ships = Ship.order(:name).map { |s| { id: s.id, name: s.name, jump_drive: s.jump_drive } }
    render json: ships
  end

  def last_jump
    ship = Ship.find(params[:id])
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
end
