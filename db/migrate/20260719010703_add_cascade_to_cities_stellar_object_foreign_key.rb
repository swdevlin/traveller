class AddCascadeToCitiesStellarObjectForeignKey < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :cities, :stellar_objects
    add_foreign_key :cities, :stellar_objects, on_delete: :cascade
  end
end
