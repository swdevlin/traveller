# frozen_string_literal: true

class ConvertJsonColumnsToJsonb < ActiveRecord::Migration[8.1]
  def up
    # Drop the partial index that uses text extraction — will be recreated as jsonb containment
    remove_index :stellar_objects, name: 'index_stellar_objects_native_sophont'

    change_column :stellar_objects, :data, :jsonb, default: {}, null: false, using: 'data::jsonb'
    change_column :stellar_objects, :characteristics, :jsonb, using: 'characteristics::jsonb'
    change_column :star_systems, :meta, :jsonb, using: 'meta::jsonb'

    # Recreate partial indexes using jsonb containment operator
    add_index :stellar_objects, :star_system_id,
              where: "data @> '{\"native_sophont\": true}'",
              name: 'index_stellar_objects_native_sophont'

    add_index :stellar_objects, :star_system_id,
              where: "data @> '{\"extinct_sophont\": true}'",
              name: 'index_stellar_objects_extinct_sophont'
  end

  def down
    remove_index :stellar_objects, name: 'index_stellar_objects_native_sophont'
    remove_index :stellar_objects, name: 'index_stellar_objects_extinct_sophont'

    change_column :stellar_objects, :data, :json, default: {}, null: false, using: 'data::json'
    change_column :stellar_objects, :characteristics, :json, using: 'characteristics::json'
    change_column :star_systems, :meta, :json, using: 'meta::json'

    add_index :stellar_objects, :star_system_id,
              where: "(data->>'native_sophont') = 'true'",
              name: 'index_stellar_objects_native_sophont'
  end
end
