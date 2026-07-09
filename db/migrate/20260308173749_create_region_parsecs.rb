class CreateRegionParsecs < ActiveRecord::Migration[8.1]
  def change
    create_table :region_parsecs do |t|
      t.references :region_component, null: false, foreign_key: true
      t.references :parsec, null: false, foreign_key: true
      t.string :kind, null: false

      t.timestamps
    end

    add_index :region_parsecs, %i[region_component_id parsec_id kind], unique: true
  end
end
