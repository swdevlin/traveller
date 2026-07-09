class AddTokenSecretToCampaigns < ActiveRecord::Migration[8.1]
  def up
    Campaign.find_each do |campaign|
      next if campaign.token_secret.present?

      campaign.update_column(:settings, (campaign.settings || {}).merge('token_secret' => SecureRandom.hex(32)))
    end
  end

  def down
    Campaign.find_each do |campaign|
      campaign.update_column(:settings, (campaign.settings || {}).except('token_secret'))
    end
  end
end
