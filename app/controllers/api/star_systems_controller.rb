class Api::StarSystemsController < Api::BaseController
  helper ApplicationHelper
  helper StellarObjectsHelper

  before_action :authenticate_user_or_token!, only: %i[update]

  # Finds systems by name, hex code or sector name; see StarSystemFinder.
  def search
    sector_id = nil
    if params[:sector_id].present?
      sector_id = Integer(params[:sector_id].to_s, exception: false)
      return render json: { error: 'sector_id must be a whole number' }, status: :bad_request unless sector_id
    end

    render json: StarSystemFinder.new(query: params[:q], referee: Current.referee_access?, sector_id: sector_id).call
  end

  def show
    authenticated_by_session?
    Current.api_token_authenticated = authenticated_by_token?
    @is_referee = Current.referee_access?
    @star_system = StarSystem
                   .includes({ parsec: { sector: :subsectors } }, :allegiance, :facilities,
                              { stars: [{ stellar_objects: [{ moons: %i[allegiance orbiting] }, :allegiance, :orbiting] }, :companion,
                                        { stars: [{ stellar_objects: [{ moons: %i[allegiance orbiting] }, :allegiance, :orbiting] }, :companion] }] },
                              main_world: :trade_codes)
                   .find_by(id: params[:id])
    render json: { error: 'star system not found' }, status: :not_found unless @star_system
  end

  def update
    star_system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'star system not found' }, status: :not_found unless star_system

    if star_system.update(star_system_params)
      render json: { name: star_system.name, known: star_system.known?, survey_index: star_system.survey_index }
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
    params.permit(:name, :known, :survey_index)
  end
end
