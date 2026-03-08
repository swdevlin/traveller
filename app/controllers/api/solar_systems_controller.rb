class Api::SolarSystemsController < Api::BaseController
  def index
    @star_systems = star_systems_in_region
    if @star_systems.nil?
      render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
             status: :bad_request
    end
  end
end
