# frozen_string_literal: true

# Serializes a StarSystem into the primaryStar tree shape expected by the
# generator service's POST /orbit_mechanics endpoint. Kept separate from
# StarSystemGeneratorSerializer (used for POST /social_characteristics) since
# the two endpoints want different wrapping and different per-node fields.
class OrbitMechanicsSerializer
  def initialize(star_system)
    @star_system = star_system
  end

  def serialize
    { 'primaryStar' => serialize_star(@star_system.primary_star) }
  end

  private

  def serialize_star(star)
    result = orbit_attributes(star)
    result['orbitType'] = star_orbit_type(star)
    result['stellarObjects'] = []
    star.stars.order(:orbit).each { |child| result['stellarObjects'] << serialize_star(child) }
    star.stellar_objects.order(:orbit).each { |so| result['stellarObjects'] << serialize_stellar_object(so) }
    result
  end

  def serialize_stellar_object(so)
    result = orbit_attributes(so)
    result['orbitType'] = so.orbit_type if so.respond_to?(:orbit_type)
    result['moons'] = so.moons.map { |m| orbit_attributes(m) } if so.respond_to?(:moons)
    result
  end

  def orbit_attributes(obj)
    {
      'orbitSequence' => obj.orbit_sequence,
      'orbit' => obj.orbit,
      'eccentricity' => obj.eccentricity,
      'inclination' => obj.inclination,
      'orbitPosition' => { 'x' => obj.orbit_x, 'y' => obj.orbit_y }
    }
  end

  def star_orbit_type(star)
    return OrbitType::VALUES[:primary] if star.orbiting.nil?
    return OrbitType::VALUES[:companion] if star.orbiting.companion_id == star.id

    star.orbit.to_i
  end
end
