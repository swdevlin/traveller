class CreateCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :campaigns do |t|
      t.references :referee, null: false, foreign_key: { to_table: :users }
      t.string :slug, null: false
      t.string :name, null: false
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :campaigns, :slug, unique: true
  end
end
