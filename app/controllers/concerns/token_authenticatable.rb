module TokenAuthenticatable
  extend ActiveSupport::Concern

  private

  def authenticated_by_token?
    token = request.headers['Authorization']&.delete_prefix('Bearer ')
    token.present? && ActiveSupport::SecurityUtils.secure_compare(token, Current.campaign.api_token.to_s)
  end
end
