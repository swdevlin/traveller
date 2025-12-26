class AddBuildLogToParsecsAndStellarObjectsAndSubsectorsAndSectors < ActiveRecord::Migration[8.1]
  def change
    add_column :parsecs, :build_log, :jsonb
    add_column :stellar_objects, :build_log, :jsonb
    add_column :subsectors, :build_log, :jsonb
    add_column :sectors, :build_log, :jsonb
    add_column :solar_systems, :build_log, :jsonb
  end
end
