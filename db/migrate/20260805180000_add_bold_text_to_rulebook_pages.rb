class AddBoldTextToRulebookPages < ActiveRecord::Migration[8.1]
  def change
    add_column :rulebook_pages, :bold_text, :text

    remove_index :rulebook_pages, :search_vector, using: :gin
    remove_column :rulebook_pages, :search_vector, :virtual, type: :tsvector, stored: true, as: <<~SQL.squish
      setweight(to_tsvector('english', coalesce(heading, '')), 'A') ||
      setweight(to_tsvector('english', coalesce(item_lines, '')), 'C') ||
      setweight(to_tsvector('english', coalesce(normalized_body, '')), 'B')
    SQL

    add_column :rulebook_pages, :search_vector, :virtual, type: :tsvector, stored: true, as: <<~SQL.squish
      setweight(to_tsvector('english', coalesce(heading, '')), 'A') ||
      setweight(to_tsvector('english', coalesce(item_lines, '')), 'C') ||
      setweight(to_tsvector('english', coalesce(bold_text, '')), 'D') ||
      setweight(to_tsvector('english', coalesce(normalized_body, '')), 'B')
    SQL

    add_index :rulebook_pages, :search_vector, using: :gin
  end
end
