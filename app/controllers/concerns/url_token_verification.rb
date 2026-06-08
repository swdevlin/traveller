module UrlTokenVerification
  extend ActiveSupport::Concern

  included do
    before_action :verify_url_token, if: -> { !authenticated? }
  end

  private

  def verify_url_token
    base_path = request.path.sub(/\.[a-z0-9]+\z/i, '')
    expected = current_campaign.token_for(base_path)
    provided = params[:token].to_s
    head :forbidden unless ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end
end
