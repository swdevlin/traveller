class AddLanguageToCities < ActiveRecord::Migration[8.1]
  def change
    add_column :cities, :language, :string
  end
end
