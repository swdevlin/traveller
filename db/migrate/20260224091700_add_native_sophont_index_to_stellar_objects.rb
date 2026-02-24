# frozen_string_literal: true

class AddNativeSophontIndexToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_index :stellar_objects, :star_system_id,
              where: "(data->>'native_sophont') = 'true'",
              name: 'index_stellar_objects_native_sophont'
  end
end
