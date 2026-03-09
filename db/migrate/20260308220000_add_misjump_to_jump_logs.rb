class AddMisjumpToJumpLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :jump_logs, :misjump, :boolean, null: false, default: false
  end
end
