# frozen_string_literal: true

class AddKnownToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :known, :boolean, default: false, null: false
  end
end
