class AddBuildSourceToSubsectors < ActiveRecord::Migration[8.1]
  def change
    add_column :subsectors, :build_source, :string
  end
end
