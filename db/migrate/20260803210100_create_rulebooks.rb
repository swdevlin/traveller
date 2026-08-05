class CreateRulebooks < ActiveRecord::Migration[8.1]
  def change
    create_table :rulebooks do |t|
      t.string   :title,                   null: false
      t.string   :short_title
      t.string   :edition
      t.integer  :publication_year
      t.string   :category,                null: false, default: 'rulebook'
      t.string   :status,                  null: false, default: 'pending'
      t.boolean  :searchable,              null: false, default: true
      t.integer  :page_number_offset,      null: false, default: 0
      t.string   :file_checksum
      t.datetime :imported_at
      t.text     :import_error
      t.jsonb    :header_footer_patterns,  null: false, default: []

      t.timestamps
    end

    add_index :rulebooks, :status
    add_index :rulebooks, :searchable
    add_index :rulebooks, :file_checksum, unique: true, where: 'file_checksum IS NOT NULL'
  end
end
