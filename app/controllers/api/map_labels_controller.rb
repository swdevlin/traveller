class Api::MapLabelsController < Api::BaseController
  limit_bounding_box only: :index

  def index
    parsecs = parsecs_in_region
    return render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
                  status: :bad_request if parsecs.nil?

    authenticated_by_session?
    @is_referee = Current.owns_campaign?
    @map_labels = parsecs.where(visible: true).labeled
  end
end
