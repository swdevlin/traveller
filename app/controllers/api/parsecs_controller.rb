class Api::ParsecsController < Api::BaseController
  def index
    @parsecs = Parsec.includes(:sector, :star_systems)
                     .where(sector_id: params[:sector_id])
                     .order(:x, y: :desc)
    render json: @parsecs.map { |p|
      system_name = p.star_systems.first&.name.presence
      { id: p.id, hex_code: p.hex_code, x: p.x, y: p.y, system_name: system_name }
    }
  end
end
