class Api::ParsecsController < Api::BaseController
  before_action :authenticate_user_or_token!, only: %i[update]

  def index
    @parsecs = Parsec.includes(:sector, :star_systems)
                     .where(sector_id: params[:sector_id])
                     .order(:x, y: :desc)
    render json: @parsecs.map { |p|
      system_name = p.star_systems.first&.name.presence
      { id: p.id, hex_code: p.hex_code, x: p.x, y: p.y, system_name: system_name }
    }
  end

  def update
    parsec = Parsec.find_by(id: params[:id])
    return render json: { error: 'parsec not found' }, status: :not_found unless parsec

    if parsec.update(parsec_params)
      render json: { survey_index: parsec.survey_index }
    else
      render json: { errors: parsec.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def parsec_params
    params.permit(:survey_index)
  end
end
