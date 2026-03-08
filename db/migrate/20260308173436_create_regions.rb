class CreateRegions < ActiveRecord::Migration[8.1]
  def change
    create_table :regions do |t|
      t.string :name, null: false
      t.string :label
      t.string :source, null: false, default: 'manual'
      t.string :external_source
      t.string :external_key
      t.jsonb :data, default: {}, null: false
      t.references :allegiance, null: true, foreign_key: true
      t.boolean :customized, default: false, null: false
      t.text :notes

      t.timestamps
    end

    add_index :regions, %i[external_source external_key],
              unique: true,
              where: 'external_source IS NOT NULL AND external_key IS NOT NULL'
  end
end
