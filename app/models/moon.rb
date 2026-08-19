class Moon < StellarObject
  include GeneratorMappings
  include HasUwp
  include NormalizesPlanetaryData

  validates :size_code, inclusion: { in: StellarObject::SIZE_CODES }

  def self.permitted_params
    [
      :name, :notes, :orbit, :inclination, :eccentricity, :diameter, :mass, :size_code,
      :period, :rotation, :retrograde, :density, :gravity,
      :temperature, :axial_tilt, :albedo, :greenhouse,
      :native_sophont, :extinct_sophont, :habitability_rating, :biomass_rating,
      :biodiversity_rating, :biocomplexity_rating, :resource_rating,
      *uwp_attribute_names
    ]
  end

  generator_data_map(
    albedo: 'albedo',
    period: 'period',
    temperature: 'meanTemperature',
    density: 'density',
    gravity: 'gravity',
    axial_tilt: 'axialTilt',
    greenhouse: 'greenhouse',
    retrograde: 'retrograde',
    habitability_rating: 'habitabilityRating',
    biomass_rating: 'biomassRating',
    biocomplexity_rating: 'biocomplexityCode',
    biodiversity_rating: 'biodiversityRating',
    compatibility_rating: 'compatibilityRating',
    extinct_sophont: 'extinctSophont',
    native_sophont: 'nativeSophont',
    rotation: 'rotation',
    resource_rating: 'resourceRating',
    atmosphere: 'atmosphere',
    hydrographics: 'hydrographics',
    population: 'population',
    law_level: 'lawLevel',
    starport_code: 'starPort',
    tidal_lock: 'tidalLock',
    tidal_lock_note: 'tidalLockNote',
    twilight_zone: 'twilightZone',
    sidereal_day: 'siderealDay',
    economics: 'economics'
    )

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
