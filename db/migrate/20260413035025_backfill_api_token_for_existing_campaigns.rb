# frozen_string_literal: true

class BackfillApiTokenForExistingCampaigns < ActiveRecord::Migration[8.1]
  def up
    Campaign.where(api_token: nil).each do |campaign|
      campaign.update_column(:api_token, SecureRandom.hex(32))
    end
  end

  def down
    # Tokens are not reversible
  end
end
