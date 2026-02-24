class RemoveStarSystemFromStellarObjects < ActiveRecord::Migration[8.1]
  def change
    # Remove the old "parsec OR star_system" constraint
    remove_check_constraint :stellar_objects,
                            name: 'stellar_objects_parsec_or_star_system_present'

    # Keep star_system_id (now used by Star rows to point to their system).
    # Add new XOR constraint that exempts Stars (primary stars have both null).
    add_check_constraint :stellar_objects,
                         "(type = 'Star') OR ((parsec_id IS NULL) <> (orbiting_id IS NULL))",
                         name: 'stellar_objects_parsec_xor_orbiting_present'
  end
end
