class CreateTagsAndTaggings < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end
    add_index :tags, :name, unique: true

    create_table :taggings do |t|
      t.references :tag, null: false, foreign_key: true
      t.references :taggable, polymorphic: true, null: false
      t.timestamps
    end
    add_index :taggings, %i[tag_id taggable_type taggable_id], unique: true, name: 'index_taggings_uniqueness'

    %i[sectors subsectors star_systems stellar_objects regions].each do |table|
      remove_column table, :tags, :string, array: true, default: [], null: false
    end
  end
end
