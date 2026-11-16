class Api::SubsectorLookupController < Api::BaseController
  def show
    x = params[:x].to_i
    y = params[:y].to_i
    subsector = Parsec.find_by(x: x, y: y)&.subsector
    sector = subsector&.sector

    if subsector
      render json: {
        id: subsector.id,
        name: subsector.name,
        letter: subsector.letter,
        sector: { id: sector.id, name: sector.name }
      }
    else
      render json: { error: 'No subsector at this point' }, status: :not_found
    end
  end
end
