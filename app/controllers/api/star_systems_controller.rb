class Api::StarSystemsController < Api::BaseController
  helper ApplicationHelper
  helper StellarObjectsHelper

  before_action :authenticate_user_or_token!, only: %i[update]

  def index
    @star_systems = star_systems_in_region
    if @star_systems.nil?
      render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
             status: :bad_request
    end
  end

  def show
    @star_system = StarSystem
                   .includes({ parsec: { sector: :subsectors } }, :allegiance, :main_world, :trade_codes, :facilities,
                              stars: [{ stellar_objects: [{ moons: %i[allegiance orbiting] }, :allegiance, :orbiting] }, :companion,
                                      { stars: [{ stellar_objects: [{ moons: %i[allegiance orbiting] }, :allegiance, :orbiting] }, :companion] }])
                   .find_by(id: params[:id])
    render json: { error: 'star system not found' }, status: :not_found unless @star_system
  end

  def update
    star_system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'star system not found' }, status: :not_found unless star_system

    if star_system.update(star_system_params)
      render json: { known: star_system.known?, survey_index: star_system.survey_index }
    else
      render json: { errors: star_system.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def ship_traffic
    star_system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'star system not found' }, status: :not_found unless star_system
    return render json: { error: 'no main world' }, status: :unprocessable_entity unless star_system.main_world

    traffic = DailyTrafficCalculator.new(
      importance: star_system.main_world_importance,
      wtn: star_system.main_world_wtn,
      frontier: params[:frontier] == '1'
    ).calculate

    render json: {
      result: traffic.result,
      effective_importance: traffic.effective_importance,
      tier_label: traffic.tier_label,
      modifiers: traffic.modifiers
    }
  end

  private

  def star_system_params
    params.permit(:known, :survey_index)
  end
end
