class Api::RoguesController < Api::BaseController
  def index
    parsecs = parsecs_in_region
    return render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
                  status: :bad_request if parsecs.nil?

    parsec_ids_with_systems = StarSystem.where(parsec: parsecs).pluck(:parsec_id)

    @rogues = StellarObject
                .where(parsec: parsecs.where.not(id: parsec_ids_with_systems))
                .where(orbiting_id: nil)
                .includes(:parsec)
  end
end
