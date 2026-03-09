class Api::ParsecsController < Api::BaseController
  def index
    @parsecs = Parsec.includes(:sector)
                     .where(sector_id: params[:sector_id])
                     .order(:x, y: :desc)
    render json: @parsecs.map { |p| { id: p.id, hex_code: p.hex_code, x: p.x, y: p.y } }
  end
end
