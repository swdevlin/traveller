# frozen_string_literal: true

# How a planet and its moons are drawn on the moon maps (MoonOrbitMap): the
# bodies on the map, their sizes, and the image or fill that represents them.
module MoonMapAppearance
  include StellarObjectAppearance

  MIN_MOON_RADIUS = 3.0
  MAX_MOON_RADIUS = 9.0
  RING_ICON_RADIUS = 9

  private

  # Moons and rings in orbit order. Rings are always shown; significant_only drops the small moons.
  def map_bodies(planet, significant_only)
    planet.moons_and_rings(significant_only: significant_only).to_a
  end

  def ring?(body)
    body.type == 'Ring'
  end

  # Moons grow with their size code (0 and S are the smallest), between the given radii.
  def moon_radius(moon, min: MIN_MOON_RADIUS, max: MAX_MOON_RADIUS)
    index = StellarObject::SIZE_CODES.index(moon.size_code.to_s) || 0
    min + ((max - min) * index / (StellarObject::SIZE_CODES.size - 1))
  end

  def moon_fill(moon)
    terrestrial_colour(moon)
  end

  def moon_image(moon)
    terrestrial_image(moon)
  end

  def planet_fill(planet)
    planet.is_a?(GasGiant) ? GAS_GIANT_COLOUR : terrestrial_colour(planet)
  end

  def planet_image(planet)
    planet.is_a?(GasGiant) ? gas_giant_image(planet) : terrestrial_image(planet)
  end

  def body_label(body)
    body.name.presence || body.orbit_sequence.to_s
  end

  def format_orbit(orbit)
    precision = orbit.to_f < 10 ? 1 : 0
    format("%.#{precision}f", orbit.to_f).sub(/\.0\z/, '')
  end

  def format_distance(moon)
    km = moon.distance_km
    return format_orbit(moon.orbit) unless km

    "#{ActiveSupport::NumberHelper.number_to_rounded(km, precision: 3, significant: true, delimiter: ',')} km"
  end
end
