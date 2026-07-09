class Api::StarSystemController < Api::BaseController
  helper ApplicationHelper, StellarObjectsHelper

  def show
    unless params[:sx].present? && params[:sy].present? && params[:hx].present? && params[:hy].present?
      return render json: { error: 'sx, sy, hx, hy required' }, status: :bad_request
    end

    sx = params[:sx].to_i
    sy = params[:sy].to_i
    hx = params[:hx].to_i
    hy = params[:hy].to_i

    parsec_x = sx * 32 + hx - 1
    parsec_y = sy * 40 - hy + 1

    parsec = Parsec.joins(:sector).find_by(x: parsec_x, y: parsec_y, sectors: { x: sx, y: sy })
    unless parsec
      return render json: { error: 'solar system not found' }, status: :not_found
    end

    authenticated_by_session?
    @is_referee = Current.user.present?

    @star_system = parsec.star_systems
                         .includes({ parsec: { sector: :subsectors } }, :allegiance, :main_world, :trade_codes, :facilities,
                   stars: [{ stellar_objects: :moons }, :companion,
                           { stars: [{ stellar_objects: :moons }, :companion] }])
                         .first
    unless @star_system
      render json: { error: 'solar system not found' }, status: :not_found
    end
  end
end
