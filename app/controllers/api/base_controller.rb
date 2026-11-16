class Api::BaseController < ActionController::API
  include ActionController::Cookies
  include TokenAuthenticatable

  before_action :set_current_campaign
  before_action :resolve_referee_access

  helper_method :current_campaign
  helper MarkdownHelper

  # The largest bounding box a limited endpoint accepts: a 2x2 block of
  # subsectors (a subsector is 8x10).
  MAX_BOUNDING_BOX_COLUMNS = 16
  MAX_BOUNDING_BOX_ROWS = 20

  # Rejects a bounding box (ulx, uly, lrx, lry) larger than 16 columns by 20
  # rows with a 400. Only the box is limited: a request that gives a sector
  # (sx, sy) is unaffected, since viewport_bounds uses the sector and a sector
  # is already no larger than 32x40. Takes before_action options.
  def self.limit_bounding_box(**options)
    before_action(**options) do
      columns = params[:lrx].to_i - params[:ulx].to_i + 1
      rows = params[:uly].to_i - params[:lry].to_i + 1
      sector_given = params[:sx].present? && params[:sy].present?
      next if sector_given || (columns <= MAX_BOUNDING_BOX_COLUMNS && rows <= MAX_BOUNDING_BOX_ROWS)

      render json: { error: "bounding box must be no larger than #{MAX_BOUNDING_BOX_COLUMNS} columns by #{MAX_BOUNDING_BOX_ROWS} rows" },
             status: :bad_request
    end
  end

  def default_url_options
    params[:campaign_slug].present? ? { campaign_slug: params[:campaign_slug] } : {}
  end

  private

  def resolve_referee_access
    authenticated_by_session?
    Current.api_token_authenticated = authenticated_by_token?
  end

  def set_current_campaign
    campaign = Campaign.find_by(slug: params[:campaign_slug])
    return render json: { error: 'Campaign not found' }, status: :not_found unless campaign

    Current.campaign = campaign
  end

  # Require authentication for endpoints that modify data. Accepts either a
  # valid session cookie belonging to the campaign's referee or a Bearer API
  # token.
  def authenticate_user_or_token!
    return if authenticated_by_session? && Current.owns_campaign?
    return if authenticated_by_token?

    return render json: { error: 'Forbidden' }, status: :forbidden if Current.session

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

  # A list query parameter in the API's public form: `name=1,2,3`. Returns an
  # array of non-blank strings; anything that isn't a string (including the
  # Rails `name[]=` array form) is treated as absent.
  def comma_list_param(name)
    value = params[name]
    return [] unless value.is_a?(String)

    value.split(',').map(&:strip).reject(&:blank?)
  end

  # A boolean query parameter in the API's public form: `true`, `1`, `false`
  # or `0`. Absent or blank is false. Returns :invalid for anything else.
  def boolean_param(name)
    value = params[name]
    return false if value.blank?
    return :invalid unless value.is_a?(String)

    case value.downcase
    when 'true', '1' then true
    when 'false', '0' then false
    else :invalid
    end
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
end
