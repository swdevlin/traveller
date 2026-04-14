# frozen_string_literal: true

class Api::ShipsController < Api::BaseController
  def index
    ships = Ship.order(:name).map { |s| { id: s.id, name: s.name, jump_drive: s.jump_drive } }
    render json: ships
  end
end
