class Api::StellarObjectsController < Api::BaseController
  helper ApplicationHelper, StellarObjectsHelper

  def show
    @stellar_object = StellarObject
                      .includes(:moons, :orbiting, :parsec, :allegiance)
                      .find_by(id: params[:id])
    render json: { error: 'stellar object not found' }, status: :not_found unless @stellar_object
  end
end
