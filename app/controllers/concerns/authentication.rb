module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    before_action :require_campaign
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
      skip_before_action :require_campaign, **options
    end

    def optional_authentication(**options)
      skip_before_action :require_authentication, **options
      skip_before_action :require_campaign, **options
      before_action :resume_session, **options
    end

    def allow_without_campaign(**options)
      skip_before_action :require_campaign, **options
    end
  end

  private

    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      return unless cookies.signed[:session_id]

      session = Session.find_by(id: cookies.signed[:session_id])
      return unless session

      if params[:campaign_slug].present?
        campaign = Campaign.find_by(slug: params[:campaign_slug])
        return if campaign && campaign.referee_id != session.user_id
      end

      session
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      return validate_return_to(session.delete(:return_to_after_authenticating)) if session[:return_to_after_authenticating].present?

      campaign = Campaign.where(referee_id: Current.user.id).first
      campaign ? sectors_path(campaign_slug: campaign.slug) : new_campaign_path
    end

    def validate_return_to(url)
      return nil if url.blank?
      uri = URI.parse(url)
      uri.host.nil? || uri.host == request.host ? url : nil
    rescue URI::InvalidURIError
      nil
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end

    def require_campaign
      return unless Current.user
      redirect_to new_campaign_path unless Campaign.exists?(referee_id: Current.user.id)
    end
end
