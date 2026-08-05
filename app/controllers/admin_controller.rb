class AdminController < ApplicationController
  # Mission Control Jobs' own ApplicationController defines
  # `default_url_options` (returning `{ server_id: ... }`), which shadows
  # this app's version for any redirect issued while handling a request
  # mounted under it — including the `redirect_to new_session_path` that
  # `require_authentication` would otherwise trigger for logged-out
  # visitors, breaking with UrlGenerationError. Avoid that redirect
  # entirely: resume the session without forcing it, then 404 anyone
  # (logged out or logged in) who isn't an admin.
  # optional_authentication resumes the session (populating Current.user if
  # logged in) without forcing a redirect, and also skips the campaign
  # requirement since this is a global tool not tied to any one campaign.
  optional_authentication

  before_action :require_admin
  before_action :set_noindex

  private

  def require_admin
    head :not_found unless Current.user&.admin?
  end

  def set_noindex
    @noindex = true
  end
end
