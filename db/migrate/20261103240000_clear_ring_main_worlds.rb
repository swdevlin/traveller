class ClearRingMainWorlds < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE star_systems SET main_world_id = NULL
      WHERE main_world_id IN (SELECT id FROM stellar_objects WHERE type = 'Ring')
    SQL
  end

  def down; end
end
