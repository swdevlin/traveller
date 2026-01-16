class RemoveStarSystemFromStellarObjects < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :stellar_objects,
                            name: 'stellar_objects_parsec_or_star_system_present'

    remove_reference :stellar_objects, :star_system, foreign_key: true

    add_check_constraint :stellar_objects,
                         '(parsec_id IS NULL) <> (orbiting_star_id IS NULL)',
                         name: 'stellar_objects_parsec_xor_orbiting_star_present'
  end
end
