class SplitNotesIntoPlayerAndRefereeNotes < ActiveRecord::Migration[8.1]
  TABLES = %i[sectors subsectors regions star_systems stellar_objects].freeze

  def change
    TABLES.each do |table|
      rename_column table, :notes, :player_notes
      add_column table, :referee_notes, :text
    end
  end
end
