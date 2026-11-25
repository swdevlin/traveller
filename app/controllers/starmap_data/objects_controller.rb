# GET /c/:campaign_slug/starmap/data/objects/:id
#
# A planet, belt, gas giant or moon as the starmap opens it: the full object, plus a count of its
# moons and its rings, which the system tree leaves out (StellarObjectSummary). The moons and
# planetoids are listed a page at a time by #moons and #planetoids, one row each, and opened here
# when clicked. The rows are read without building records, so the generator data that makes up most
# of a record stays in the database.
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

  private

  # A ring's span is in its data, which no moon is asked for.
  def moons_scope(stellar_object)
    super.select(:id, :type, :name, :uwp, :orbit, :orbit_sequence, Arel.sql("CASE WHEN type = 'Ring' THEN data END AS data"))
  end
end
