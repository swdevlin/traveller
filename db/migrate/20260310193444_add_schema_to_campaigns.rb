class AddSchemaToCampaigns < ActiveRecord::Migration[8.1]
  def change
    add_column :campaigns, :schema_name, :string, null: false
  end
end
