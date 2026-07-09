class Api::SubsectorLookupController < Api::BaseController
  def show
    x = params[:x].to_i
    y = params[:y].to_i
    subsector = Parsec.find_by(x: x, y: y)&.subsector

    if subsector
      render json: { url: "/c/#{current_campaign.slug}/subsectors/#{subsector.id}" }
    else
      render json: { error: 'No subsector at this point' }, status: :not_found
    end
  end
end
