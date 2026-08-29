class CreateSystemQueries < ActiveRecord::Migration[8.1]
  def change
    create_table :system_queries do |t|
      t.string :name,      null: false
      t.jsonb  :rule_data, null: false, default: {}
      t.jsonb  :columns,   null: false, default: []

      t.timestamps
    end
  end
end
