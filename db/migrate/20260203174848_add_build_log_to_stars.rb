class AddBuildLogToStars < ActiveRecord::Migration[8.1]
  def change
    add_column :stars, :build_log, :jsonb
  end
end
