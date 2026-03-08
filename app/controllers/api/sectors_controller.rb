class Api::SectorsController < Api::BaseController
  def index
    @sectors = Sector.all
  end
end
