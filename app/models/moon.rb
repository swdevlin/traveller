class Moon < StellarObject
  include HasUwp
  include NormalizesPlanetaryData
  include HasPlanetaryBodyAttributes

  def effective_jump_shadow_km
    compute_effective_jump_shadow[:km]
  end

  def effective_jump_shadow_source
    compute_effective_jump_shadow[:source]
  end

  private

  def compute_effective_jump_shadow
    @compute_effective_jump_shadow ||= begin
      planet = orbiting
      return { km: jump_shadow, source: nil } if planet.nil?

      best = { km: jump_shadow, source: nil }

      moon_to_planet_km = (orbit || 0) * (planet.diameter || 0)

      planet_remaining = planet.jump_shadow - moon_to_planet_km
      best = { km: planet_remaining, source: planet } if planet_remaining > best[:km]

      cumulative_distance_km = moon_to_planet_km + planet.orbit_distance_from_parent_km

      star = planet.orbiting
      while star.present?
        star_remaining = star.jump_shadow - cumulative_distance_km
        best = { km: star_remaining, source: star } if star_remaining > best[:km]
        cumulative_distance_km += star.orbit_distance_from_parent_km
        star = star.orbiting
      end

      best
    end
  end
end
