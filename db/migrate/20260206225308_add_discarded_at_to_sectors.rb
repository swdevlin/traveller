class AddDiscardedAtToSectors < ActiveRecord::Migration[8.1]
  def change
    add_column :sectors, :discarded_at, :datetime
    add_index :sectors, :discarded_at
  end
end
