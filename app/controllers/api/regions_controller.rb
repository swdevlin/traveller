class Api::RegionsController < Api::BaseController
  def index
    @regions = Region.includes(region_parsecs: :parsec).all
  end
end
