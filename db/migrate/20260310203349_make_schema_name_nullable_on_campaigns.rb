class MakeSchemaNameNullableOnCampaigns < ActiveRecord::Migration[8.1]
  def change
    change_column_null :campaigns, :schema_name, true
  end
end
