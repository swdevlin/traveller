class AddCityTypeAndCapitalDesignationToCities < ActiveRecord::Migration[8.1]
  def change
    add_column :cities, :city_type, :string
    add_column :cities, :capital_designation, :string
  end
end
