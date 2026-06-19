class AddCompletedToursToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :completed_tours, :jsonb, default: [], null: false
  end
end
