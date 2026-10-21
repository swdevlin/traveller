# frozen_string_literal: true

# Where a body sits on the schematic system map. A port of the generator's `moonOrbitPosition`
# (system-generation/utils/orbitPosition.js): a random point in time on the orbit is chosen, Kepler's equation
# is solved for it, and the result is offset by the position of the body being orbited. The random draws are taken
# once, in the generator's order, so an instance always answers the same and matches the generator for identical
# draws.
class OrbitPositionCalculator
  NEWTON_ITERATIONS = 6

  attr_reader :semi_major_axis, :eccentricity, :argument_of_periapsis, :longitude_of_ascending_node, :mean_anomaly

  # A moon's orbit is in planetary diameters. Positions are absolute to the primary star, so a planet whose own
  # position is unknown can't place a moon: answers nil.
  def self.for_moon(moon:, planet:, random: Random.new)
    return unless moon.orbit.present? && planet.diameter.present? && planet.orbit_x.present? && planet.orbit_y.present?

    new(semi_major_axis: moon.orbit.to_f * planet.diameter.to_f, eccentricity: moon.eccentricity,
        centre_x: planet.orbit_x, centre_y: planet.orbit_y, random: random)
  end

  # A body's orbit is an orbit number. The primary star has no position of its own: it is the origin.
  def self.for_body_orbiting_star(body:, star:, random: Random.new)
    return if body.orbit.blank?

    new(semi_major_axis: OrbitToAu.convert(body.orbit) * StellarConstants::AU_TO_KM, eccentricity: body.eccentricity,
        centre_x: star.orbit_x, centre_y: star.orbit_y, random: random)
  end

  # @param semi_major_axis [Numeric] km
  # @param centre_x [Numeric, nil] km, the position of the body being orbited
  # @param random [Random] anything responding to `rand(range)`
  def initialize(semi_major_axis:, eccentricity:, centre_x:, centre_y:, random: Random.new)
    @semi_major_axis = semi_major_axis.to_f
    @eccentricity = eccentricity.to_f
    @centre_x = centre_x.to_f
    @centre_y = centre_y.to_f
    @argument_of_periapsis = random.rand(0.0...360.0)
    @longitude_of_ascending_node = random.rand(0.0...360.0)
    @mean_anomaly = random.rand(0.0...(Math::PI * 2))
  end

  def longitude_of_periapsis
    (longitude_of_ascending_node + argument_of_periapsis) % 360
  end

  # Newton-Raphson on M = E - e sin(E); converges quickly for planetary orbits.
  def eccentric_anomaly
    @eccentric_anomaly ||= (1..NEWTON_ITERATIONS).reduce(mean_anomaly) do |e_anomaly, _|
      e_anomaly - ((e_anomaly - (eccentricity * Math.sin(e_anomaly)) - mean_anomaly) /
                   (1 - (eccentricity * Math.cos(e_anomaly))))
    end
  end

  # Position in the moon's own orbital plane, with the planet at one focus.
  def orbital_x
    semi_major_axis * (Math.cos(eccentric_anomaly) - eccentricity)
  end

  def orbital_y
    semi_major_axis * Math.sqrt(1 - (eccentricity**2)) * Math.sin(eccentric_anomaly)
  end

  def radius
    semi_major_axis * (1 - (eccentricity * Math.cos(eccentric_anomaly)))
  end

  def periapsis
    semi_major_axis * (1 - eccentricity)
  end

  def apoapsis
    semi_major_axis * (1 + eccentricity)
  end

  def x
    (orbital_x * Math.cos(periapsis_angle)) - (orbital_y * Math.sin(periapsis_angle)) + @centre_x
  end

  def y
    (orbital_x * Math.sin(periapsis_angle)) + (orbital_y * Math.cos(periapsis_angle)) + @centre_y
  end

  private
    # The orbit is viewed face-on, so inclination is ignored, as in the generator's 2D map position.
    def periapsis_angle
      longitude_of_periapsis * Math::PI / 180
    end
end
