class Api::RegionsController < Api::BaseController
  def index
    bounds = viewport_bounds(pad: 1)
    return render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
                  status: :bad_request unless bounds

    @x_range = bounds[:x]
    @y_range = bounds[:y]
    @regions = Region.joins(:parsecs).where(parsecs: { x: @x_range, y: @y_range }).distinct
                      .includes(region_parsecs: :parsec)
  end
end
