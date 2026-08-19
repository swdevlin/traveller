class AddReferenceUrlToSectorsSubsectorsAndStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :sectors, :reference_url, :string
    add_column :subsectors, :reference_url, :string
    add_column :star_systems, :reference_url, :string
  end
end
