class AddBuildLogToStars < ActiveRecord::Migration[8.1]
  def change
    # Gutted: stars table no longer exists; build_log is a column on stellar_objects
  end
end
