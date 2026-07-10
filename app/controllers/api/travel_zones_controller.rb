# frozen_string_literal: true

class Api::TravelZonesController < Api::BaseController
  def index
    render json: TravelZone.ordered.map { |zone| { id: zone.id, code: zone.code, name: zone.name, colour: zone.colour } }
  end
end
