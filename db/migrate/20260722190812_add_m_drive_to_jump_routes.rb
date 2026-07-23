class AddMDriveToJumpRoutes < ActiveRecord::Migration[8.1]
  def change
    add_column :jump_routes, :m_drive, :integer
  end
end
