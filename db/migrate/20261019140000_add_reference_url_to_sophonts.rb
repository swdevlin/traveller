class AddReferenceUrlToSophonts < ActiveRecord::Migration[8.1]
  def change
    add_column :sophonts, :reference_url, :string
  end
end
