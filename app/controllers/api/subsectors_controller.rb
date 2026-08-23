class Api::SubsectorsController < Api::BaseController
  def show
    @subsector = Subsector.includes(:sector).find_by(id: params[:id])
    return render json: { error: 'subsector not found' }, status: :not_found unless @subsector

    @star_systems = @subsector.star_systems
                              .includes({ parsec: :sector }, :allegiance, :facilities, :stars, main_world: :trade_codes)
  end
end
