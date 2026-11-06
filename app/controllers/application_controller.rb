class ApplicationController < ActionController::Base
  prepend_before_action :set_current_campaign
  include Authentication
  # Included after Authentication so the session (and current_user) is
  # resolved before Ahoy records the visit's user_id.
  include Ahoy::Controller
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Method
  helper_method :pagy

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  after_action :track_campaign_page_view

  def default_url_options
    params[:campaign_slug].present? ? { campaign_slug: params[:campaign_slug] } : {}
  end

  private

  def set_current_campaign
    return if params[:campaign_slug].blank?

    @current_campaign = Campaign.find_by(slug: params[:campaign_slug])
    return redirect_to root_path unless @current_campaign

    Current.campaign = @current_campaign
  end

  def current_campaign
    Current.campaign
  end
  helper_method :current_campaign

  def current_user
    Current.user
  end

  def track_campaign_page_view
    # A browser's Ahoy visit is created once (from the ahoy_visit cookie) and
    # keeps its user_id from that point on — Ahoy never revisits it. Without
    # this, a visit that started before sign-in (or before this ownership fix
    # shipped) stays permanently anonymous even once Current.user is correct.
    # authenticate is a no-op once the visit already has a user.
    ahoy.authenticate(current_user) if current_user

    return if Current.campaign.blank?

    ahoy.track 'Viewed page', campaign_id: Current.campaign.id
  end

  # Only local paths are honoured, so a crafted return_to cannot redirect off-site.
  def local_return_path
    path = params[:return_to].to_s
    path if path.start_with?('/') && !path.start_with?('//') && !path.include?("\n")
  end

  def hex_mover_for(record)
    HexMover.new(record, parsec_id: params[:parsec_id], sector: Sector.kept.find_by(id: params[:sector_id]),
                         hex_code: params[:hex_code])
  end

  def flash_move_result(result, name)
    if result.success?
      flash[:notice] = "#{name} moved to #{result.parsec.sector.name} #{result.parsec.hex_code}."
    else
      flash[:alert] = "Could not move #{name}: #{result.error}"
    end
  end

  def generator_service
    GeneratorService.new(campaign_id: current_campaign&.id)
  end

  def map_service
    MapService.new(campaign_id: current_campaign&.id)
  end
end
