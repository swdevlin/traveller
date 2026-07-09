class CreateStars < ActiveRecord::Migration[8.1]
  def change
    # Gutted: Star is now an STI subclass of StellarObject stored in stellar_objects table
  end
end
