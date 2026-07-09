class Api::SectorsController < Api::BaseController
  def index
    @sectors = Sector.kept.includes(:subsectors)
  end
end
