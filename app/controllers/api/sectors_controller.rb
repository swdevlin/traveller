class Api::SectorsController < Api::BaseController
  def index
    @sectors = Sector.kept.includes(:tags, subsectors: :tags)
  end
end
