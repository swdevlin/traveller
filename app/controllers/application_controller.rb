class ApplicationController < ActionController::Base
  prepend_before_action :set_current_campaign
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Method

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

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

  def generator_service
    GeneratorService.new(campaign_id: current_campaign&.id)
  end
end
