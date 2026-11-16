class Api::RoguesController < Api::BaseController
  limit_bounding_box only: :index

  SELECTION_ERROR = 'exactly one of sector coordinates (sx, sy) or a bounding box (ulx, uly, lrx, lry) must be given'.freeze

  def index
    sector_given = params[:sx].present? || params[:sy].present?
    box_given = %i[ulx uly lrx lry].any? { |key| params[key].present? }
    return render json: { error: SELECTION_ERROR }, status: :bad_request if sector_given && box_given

    parsecs = parsecs_in_region
    return render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
                  status: :bad_request if parsecs.nil?

    @rogues = StellarObject
                .where(parsec: parsecs, orbiting_id: nil)
                .includes(:parsec)
  end
end
