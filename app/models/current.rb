class Current < ActiveSupport::CurrentAttributes
  attribute :session, :campaign, :api_token_authenticated
  delegate :user, to: :session, allow_nil: true

  def owns_campaign?
    user.present? && campaign.present? && user.id == campaign.referee_id
  end

  # The campaign API token carries referee authority (it can already write), so it sees classified records too.
  def referee_access?
    owns_campaign? || api_token_authenticated == true
  end
end
