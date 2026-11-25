# GET /c/:campaign_slug/starmap/data/objects/:id
#
# A planet, belt or gas giant as the starmap opens it: the full object, plus a count of its moons
# and its rings, which the system tree leaves out (StellarObjectSummary). The moons are listed a
# page at a time by Api::StellarObjectsController#moons.
#
# For the starmap only. The documented API is Api::StellarObjectsController, whose objects carry
# neither moons nor rings.
class StarmapData::ObjectsController < Api::StellarObjectsController
  def show
    authenticated_by_session?
    @stellar_object = StellarObject
                      .includes(:rings, :orbiting, :parsec, :allegiance, :tidal_lock_target)
                      .find_by(id: params[:id])
    render json: { error: 'stellar object not found' }, status: :not_found unless @stellar_object
  end
end
