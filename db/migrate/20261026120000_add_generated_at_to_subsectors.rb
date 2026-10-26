class AddGeneratedAtToSubsectors < ActiveRecord::Migration[8.1]
  def up
    add_column :subsectors, :generated_at, :datetime unless column_exists?(:subsectors, :generated_at)

    Subsector.reset_column_information
    latest_by_parsec = latest_object_update_by_parsec

    Subsector.find_each do |subsector|
      ul, lr = subsector.universal_coordinates
      latest = latest_by_parsec.filter_map do |(x, y), updated_at|
        updated_at if x.between?(ul.x, lr.x) && y.between?(lr.y, ul.y)
      end.max
      next if latest.nil?

      Subsector.where(id: subsector.id).update_all(generated_at: latest)
    end
  end

  def down
    remove_column :subsectors, :generated_at
  end

  private

  # Latest stellar object updated_at per parsec coordinate. An object belongs to
  # the parsec it sits in directly (rogue), that of its star system, or that of
  # the rogue it orbits (moons and rings of a rogue planet).
  def latest_object_update_by_parsec
    rows = select_rows(<<~SQL.squish)
      SELECT parsecs.x, parsecs.y, MAX(so.updated_at)
      FROM stellar_objects so
      LEFT JOIN star_systems ss ON ss.id = so.star_system_id
      LEFT JOIN stellar_objects parent ON parent.id = so.orbiting_id
      JOIN parsecs ON parsecs.id = COALESCE(so.parsec_id, ss.parsec_id, parent.parsec_id)
      GROUP BY parsecs.x, parsecs.y
    SQL
    rows.to_h { |x, y, updated_at| [[x.to_i, y.to_i], updated_at.is_a?(String) ? Time.zone.parse(updated_at) : updated_at] }
  end
end
