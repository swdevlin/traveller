class Api::MapLabelsController < Api::BaseController
  def index
    parsecs = parsecs_in_region
    return render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
                  status: :bad_request if parsecs.nil?

    authenticated_by_session?
    @is_referee = Current.user.present?
    @map_labels = parsecs.where(visible: true).labeled
  end
end
