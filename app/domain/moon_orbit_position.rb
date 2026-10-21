# frozen_string_literal: true

# Where a moon sits on the schematic system map. A port of the generator's `moonOrbitPosition`
# (system-generation/utils/orbitPosition.js): a random point in time on the orbit is chosen, Kepler's equation
# is solved for it, and the result is offset by the planet's own position. The random draws are taken once, in the
# generator's order, so an instance always answers the same and matches the generator for identical draws.
class MoonOrbitPosition
  NEWTON_ITERATIONS = 6

  attr_reader :argument_of_periapsis, :longitude_of_ascending_node, :mean_anomaly

  # @param moon [Moon] supplies orbit (planetary diameters), eccentricity
  # @param planet [StellarObject] supplies diameter (km) and its own orbit_x/orbit_y
  # @param random [Random] anything responding to `rand(range)`
  def initialize(moon:, planet:, random: Random.new)
    @moon = moon
    @planet = planet
    return unless present?

    @argument_of_periapsis = random.rand(0.0...360.0)
    @longitude_of_ascending_node = random.rand(0.0...360.0)
    @mean_anomaly = random.rand(0.0...(Math::PI * 2))
  end

  # Positions are absolute to the primary star, so a planet whose own position is unknown can't place a moon.
  def present?
    @moon.orbit.present? && @planet.diameter.present? && @planet.orbit_x.present? && @planet.orbit_y.present?
  end

  def semi_major_axis
    @moon.orbit.to_f * @planet.diameter.to_f
  end

  def eccentricity
    @moon.eccentricity.to_f
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
    (orbital_x * Math.cos(periapsis_angle)) - (orbital_y * Math.sin(periapsis_angle)) + @planet.orbit_x
  end

  def y
    (orbital_x * Math.sin(periapsis_angle)) + (orbital_y * Math.cos(periapsis_angle)) + @planet.orbit_y
  end

  private
    # The orbit is viewed face-on, so inclination is ignored, as in the generator's 2D map position.
    def periapsis_angle
      longitude_of_periapsis * Math::PI / 180
    end
end
