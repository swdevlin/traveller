# GET /c/:campaign_slug/starmap/data/hex?sx=&sy=&hx=&hy=
#
# What the starmap loads when a hex is clicked: the parsec and the star system in it, with each
# planet, belt and gas giant cut down to what the side panel and maps draw (StellarObjectSummary).
# The full object comes from StarmapData::ObjectsController when it is opened.
#
# For the starmap only, so it is free to change with it. The documented API is Api::ParsecsController,
# which returns full objects. hx and hy are 1-based within the sector, as in that API.
class StarmapData::HexesController < Api::BaseController
  include StarSystemDetailCaching

  helper ApplicationHelper, StellarObjectsHelper

  def show
    parsec = find_parsec
    return render json: { error: 'parsec not found' }, status: :not_found unless parsec

    @parsec = parsec
    @is_referee = Current.referee_access?
    star_system = parsec.star_systems.first
    return render 'starmap_data/hexes/show' unless star_system # an empty hex: nothing worth caching

    render_star_system_detail(star_system, template: 'starmap_data/hexes/show', parsec: parsec,
                                           summary: true, loader: StarmapSystemLoader)
  end

  private

  def find_parsec
    return unless %i[sx sy hx hy].all? { |key| params[key].present? }

    hx = params[:hx].to_i
    hy = params[:hy].to_i
    return unless hx.between?(1, 32) && hy.between?(1, 40)

    Parsec.find_by(x: (params[:sx].to_i * 32) + hx - 1, y: (params[:sy].to_i * 40) - hy + 1)
  end
end
