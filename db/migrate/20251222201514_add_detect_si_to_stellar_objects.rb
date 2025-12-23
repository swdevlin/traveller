class AddDetectSiToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :detect_si, :integer
    add_column :stellar_objects, :survey_index, :integer
  end
end
