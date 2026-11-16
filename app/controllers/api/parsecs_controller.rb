class Api::ParsecsController < Api::BaseController
  include StarSystemDetailCaching

  helper ApplicationHelper, StellarObjectsHelper

  before_action :authenticate_user_or_token!, only: %i[update]

  SELECTION_ERROR = 'exactly one of sector_id, subsector_id, sector coordinates (sx and sy) or ' \
                    'a bounding box (ulx, uly, lrx and lry) must be given, and only one of them; ' \
                    'hx and hy may be added to sx and sy, but only together'.freeze

  before_action :require_one_selection, only: :index
  limit_bounding_box only: :index

  # Parsecs in one sector, one subsector or a viewport.
  def index
    parsecs = selected_parsecs
    return if performed?

    render json: parsecs.includes(:sector, :star_systems).order(:x, y: :desc).map { |p|
      system_name = p.star_systems.first&.name.presence
      { id: p.id, hex_code: p.hex_code, x: p.x, y: p.y, system_name: system_name }
    }
  end

  def show
    parsec = Parsec.find_by(id: params[:id])
    return render json: { error: 'parsec not found' }, status: :not_found unless parsec

    render_parsec(parsec)
  end

  def update
    parsec = Parsec.find_by(id: params[:id])
    return render json: { error: 'parsec not found' }, status: :not_found unless parsec

    if parsec.update(parsec_params)
      render json: { survey_index: parsec.survey_index }
    else
      render json: { errors: parsec.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # A parsec with the star system in it, if there is one. Details the players
  # have not discovered are withheld unless the caller is the referee.
  def render_parsec(parsec)
    @parsec = parsec
    authenticated_by_session?
    Current.api_token_authenticated = authenticated_by_token?
    @is_referee = Current.referee_access?

    star_system = parsec.star_systems.first
    return render 'api/parsecs/show' unless star_system  # an empty hex: nothing worth caching

    render_star_system_detail(star_system, template: 'api/parsecs/show', parsec: parsec)
  end

  # Each way of choosing parsecs counts as attempted if any of its parameters
  # is present; exactly one must be attempted, and it must be complete. hx and
  # hy narrow sx and sy to one hex, so they belong to that way and must be
  # given together, or not at all.
  def require_one_selection
    attempted = [
      %i[sector_id], %i[subsector_id], %i[sx sy hx hy], %i[ulx uly lrx lry]
    ].select { |keys| keys.any? { |key| params[key].present? } }
    return if attempted.one? && selection_complete?(attempted.first)

    render json: { error: SELECTION_ERROR }, status: :bad_request
  end

  def selection_complete?(keys)
    present = keys.select { |key| params[key].present? }
    return present.size == keys.size unless keys.include?(:hx)

    present.include?(:sx) && present.include?(:sy) && (present & %i[hx hy]).size.in?([0, 2])
  end

  def selected_parsecs
    if params[:sector_id].present?
      sector = Sector.kept.find_by(id: params[:sector_id])
      return render json: { error: 'sector not found' }, status: :not_found unless sector

      Parsec.where(sector_id: sector.id)
    elsif params[:subsector_id].present?
      subsector = Subsector.kept_sector.find_by(id: params[:subsector_id])
      return render json: { error: 'subsector not found' }, status: :not_found unless subsector

      subsector.parsecs
    else
      bounds = viewport_bounds
      bounds = single_hex(bounds) if params[:hx].present?
      Parsec.where(x: bounds[:x], y: bounds[:y])
    end
  end

  def parsec_params
    params.permit(:survey_index)
  end

  # The sector's bounds narrowed to the hex at (hx, hy), which are 1-based
  # within the sector. A hex outside the sector matches nothing.
  def single_hex(bounds)
    x = bounds[:x].begin + params[:hx].to_i - 1
    y = bounds[:y].end - params[:hy].to_i + 1
    return { x: x..x, y: y..y } if bounds[:x].cover?(x) && bounds[:y].cover?(y)

    { x: 1..0, y: 1..0 }
  end
end
