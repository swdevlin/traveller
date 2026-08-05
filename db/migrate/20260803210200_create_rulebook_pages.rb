class CreateRulebookPages < ActiveRecord::Migration[8.1]
  def change
    create_table :rulebook_pages do |t|
      t.references :rulebook, null: false, foreign_key: { on_delete: :cascade }
      t.integer :pdf_page_number,              null: false
      t.integer :printed_page_number_override
      t.boolean :printed_page_unnumbered, null: false, default: false
      t.string  :heading
      t.text    :body
      t.text    :normalized_body
      t.virtual :search_vector, type: :tsvector, stored: true, as: <<~SQL.squish
        setweight(to_tsvector('english', coalesce(heading, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(normalized_body, '')), 'B')
      SQL

      t.timestamps
    end

    add_index :rulebook_pages, %i[rulebook_id pdf_page_number], unique: true
    add_index :rulebook_pages, :search_vector, using: :gin

    add_check_constraint :rulebook_pages,
                          'NOT (printed_page_unnumbered AND printed_page_number_override IS NOT NULL)',
                          name: 'rulebook_pages_override_xor_unnumbered'
  end
end
