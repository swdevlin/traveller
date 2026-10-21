class Moon < StellarObject
  include HasUwp
  include NormalizesPlanetaryData
  include HasPlanetaryBodyAttributes
  include HasPlanetMap

  validates :starport_code, presence: true

  def effective_jump_shadow_km
    compute_effective_jump_shadow[:km]
  end

  def effective_jump_shadow_source
    compute_effective_jump_shadow[:source]
  end

  private

  # A moon only changes the numbering of the moons around its own planet, so the rest of the system's
  # sequences are left alone. A planet that has not been numbered yet needs the whole system assigned.
  def reassign_orbit_sequences
    return super if orbiting&.orbit_sequence.blank?

    OrbitSequenceAssigner.new(orbit_star_system).assign_moons_of!(orbiting)
  end

  def reassign_orbit_sequences_after_destroy
    return super if orbit_star_system_for_destroy.nil? || orbiting.orbit_sequence.blank?

    OrbitSequenceAssigner.new(orbit_star_system_for_destroy).assign_moons_of!(orbiting)
  end

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
