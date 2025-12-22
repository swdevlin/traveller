class AddDataToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :data, :json, default: {}, null: false
  end
end
