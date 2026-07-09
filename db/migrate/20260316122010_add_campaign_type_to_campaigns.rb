class AddCampaignTypeToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :campaign_type, :string, null: false, default: 'charted_space'
    add_column :campaigns, :sector_source, :string
  end
end
