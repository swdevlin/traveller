class AddLanguageToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :language, :string
  end
end
