class AddMDriveToShips < ActiveRecord::Migration[8.1]
  def change
    add_column :ships, :m_drive, :integer, default: 1
  end
end
