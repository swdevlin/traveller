class Api::StarSystemsController < Api::BaseController
  helper ApplicationHelper

  def index
    @star_systems = star_systems_in_region
    if @star_systems.nil?
      render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
             status: :bad_request
    end
  end

  def show
    @star_system = StarSystem
                   .includes({ parsec: :sector }, :allegiance, :main_world, :trade_codes, :facilities,
                              stars: [{ stellar_objects: :moons }, :companion,
                                      { stars: [{ stellar_objects: :moons }, :companion] }])
                   .find_by(id: params[:id])
    render json: { error: 'star system not found' }, status: :not_found unless @star_system
  end
end
