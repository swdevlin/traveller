class Current < ActiveSupport::CurrentAttributes
  attribute :session, :campaign
  delegate :user, to: :session, allow_nil: true

  def owns_campaign?
    user.present? && campaign.present? && user.id == campaign.referee_id
  end
end
