class Api::ParsecsController < Api::BaseController
  include StarSystemDetailCaching

  helper ApplicationHelper, StellarObjectsHelper

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

  # What is at a hex: its parsec, with the star system in it if there is one.
  # `hx` and `hy` are the hex's column and row within the sector (1-based).
  def lookup
    unless %i[sx sy hx hy].all? { |key| params[key].present? }
      return render json: { error: 'sx, sy, hx, hy required' }, status: :bad_request
    end

    sx = params[:sx].to_i
    sy = params[:sy].to_i

    @parsec = Parsec.joins(:sector).find_by(x: sx * 32 + params[:hx].to_i - 1,
                                            y: sy * 40 - params[:hy].to_i + 1,
                                            sectors: { x: sx, y: sy })
    return render json: { error: 'parsec not found' }, status: :not_found unless @parsec

    authenticated_by_session?
    Current.api_token_authenticated = authenticated_by_token?
    @is_referee = Current.referee_access?

    star_system = @parsec.star_systems.first
    return render :lookup unless star_system  # an empty hex: nothing worth caching

    render_star_system_detail(star_system, template: 'api/parsecs/lookup', parsec: @parsec)
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
