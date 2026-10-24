# frozen_string_literal: true

# The schematic image (public/stellar_objects/) used to represent a body on the orbit strip,
# chosen by the same rules as the system maps. Nil when no image applies.
class OrbitStripImage
  include StellarObjectAppearance

  def self.for(body)
    new.for(body)
  end

  def for(body)
    name = case body
    when Star then star_image(body)
    when TerrestrialPlanet then terrestrial_image(body)
    when GasGiant then gas_giant_image(body)
    when PlanetoidBelt then :planetoid_belt
    end
    name && "/stellar_objects/#{name}.webp"
  end
end
