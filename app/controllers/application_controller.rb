class ApplicationController < ActionController::Base
  prepend_before_action :switch_tenant
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  include Pagy::Method

  after_action :reset_tenant

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def default_url_options
    params[:campaign_slug].present? ? { campaign_slug: params[:campaign_slug] } : {}
  end

  private

  def switch_tenant
    return if params[:campaign_slug].blank?

    @current_campaign = Campaign.find_by(slug: params[:campaign_slug])
    return redirect_to root_path unless @current_campaign

    Apartment::Tenant.switch!(@current_campaign.schema_name) if @current_campaign.schema_name.present?
  end

  def current_campaign
    @current_campaign
  end
  helper_method :current_campaign

  def reset_tenant
    Apartment::Tenant.reset
  end
end
