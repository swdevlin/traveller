class AddReferenceUrlToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :reference_url, :string
  end
end
