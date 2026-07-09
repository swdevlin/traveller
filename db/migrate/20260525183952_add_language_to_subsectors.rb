class AddLanguageToSubsectors < ActiveRecord::Migration[8.1]
  def change
    add_column :subsectors, :language, :string
  end
end
