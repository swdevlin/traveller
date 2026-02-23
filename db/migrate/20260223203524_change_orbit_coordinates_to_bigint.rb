# frozen_string_literal: true

class ChangeOrbitCoordinatesToBigint < ActiveRecord::Migration[8.1]
  def change
    change_column :stellar_objects, :orbit_x, :float
    change_column :stellar_objects, :orbit_y, :float
  end
end
