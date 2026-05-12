class FontAwesomeIcons < ActiveRecord::Migration[8.1]
  def change
    create_table :font_awesome_icons do |t|
      t.string :name, null: false
      t.string :style, null: false, default: 'regular'
      t.string :view_box, null: false
      t.text :svg_content, null: false

      t.timestamps
    end

    add_index :font_awesome_icons, [:name, :style], unique: true
  end
end
