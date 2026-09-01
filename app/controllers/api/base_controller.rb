class Api::BaseController < ActionController::API
  include ActionController::Cookies
  include TokenAuthenticatable

  before_action :set_current_campaign

  helper_method :current_campaign

  def default_url_options
    params[:campaign_slug].present? ? { campaign_slug: params[:campaign_slug] } : {}
  end

  private

  def set_current_campaign
    campaign = Campaign.find_by(slug: params[:campaign_slug])
    return render json: { error: 'Campaign not found' }, status: :not_found unless campaign

    Current.campaign = campaign
  end

  # Require authentication for endpoints that modify data. Accepts either a
  # valid session cookie (logged-in user) or a Bearer API token.
  def authenticate_user_or_token!
    return if authenticated_by_session?
    return if authenticated_by_token?

    render json: { error: 'Unauthorised' }, status: :unauthorized
  end

  def authenticated_by_session?
    return false unless cookies.signed[:session_id]

    session = Session.find_by(id: cookies.signed[:session_id])
    return false unless session

    Current.session = session
    true
  end

  def current_campaign
    Current.campaign
  end

  def viewport_bounds(pad: 0)
    if params[:sx].present? && params[:sy].present?
      sx = params[:sx].to_i
      sy = params[:sy].to_i
      { x: (sx * 32 - pad)..(sx * 32 + 31 + pad), y: (sy * 40 - 39 - pad)..(sy * 40 + pad) }
    elsif params[:ulx].present? && params[:uly].present? && params[:lrx].present? && params[:lry].present?
      { x: (params[:ulx].to_i - pad)..(params[:lrx].to_i + pad), y: (params[:lry].to_i - pad)..(params[:uly].to_i + pad) }
    end
  end

  def parsecs_in_region
    bounds = viewport_bounds
    Parsec.where(x: bounds[:x], y: bounds[:y]) if bounds
  end

  def star_systems_in_region
    parsecs = parsecs_in_region
    return nil if parsecs.nil?

    StarSystem.where(parsec: parsecs)
              .includes({ parsec: { sector: :subsectors } }, :allegiance, :facilities, stars: :stellar_objects, main_world: :trade_codes)
  end
end
