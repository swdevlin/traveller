class AddOrbitSequenceToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :orbit_sequence, :string
  end
end
