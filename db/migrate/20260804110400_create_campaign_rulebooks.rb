class CreateCampaignRulebooks < ActiveRecord::Migration[8.1]
  def change
    create_table :campaign_rulebooks do |t|
      t.bigint  :rulebook_id, null: false
      t.boolean :enabled, null: false, default: false
      t.boolean :player_searchable, null: false, default: false

      t.timestamps
    end

    add_index :campaign_rulebooks, :rulebook_id, unique: true

    add_check_constraint :campaign_rulebooks,
                          'NOT player_searchable OR enabled',
                          name: 'campaign_rulebooks_player_searchable_implies_enabled'
  end
end
