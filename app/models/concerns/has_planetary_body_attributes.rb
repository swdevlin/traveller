# frozen_string_literal: true

module HasPlanetaryBodyAttributes
  extend ActiveSupport::Concern
  include GeneratorMappings
  include HasSophont

  included do
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

    # store_accessor keeps whatever the form submits, so cast to integers or the starmap decoder gets strings.
    %i[habitability_rating biomass_rating biocomplexity_rating biodiversity_rating
       compatibility_rating resource_rating].each do |name|
      define_method(:"#{name}=") do |value|
        super(value.is_a?(String) && value.strip.match?(/\A-?\d+\z/) ? value.to_i : value)
      end
    end

    validates :size_code, inclusion: { in: StellarObject::SIZE_CODES }

    # The starmap (Elm) decoder cannot load a body without these, so every form must supply them.
    validates :inclination, :eccentricity, :axial_tilt, :albedo,
              :biomass_rating, :biocomplexity_rating, :biodiversity_rating, :compatibility_rating, :resource_rating,
              presence: true
    validates :resource_rating, numericality: { only_integer: true, in: 2..12 }, allow_nil: true
  end

  class_methods do
    def permitted_params
      [
        :name, :player_notes, :referee_notes, :reference_url, :orbit, :inclination, :eccentricity, :diameter, :mass, :size_code,
        :period, :rotation, :retrograde, :density, :gravity,
        :temperature, :axial_tilt, :albedo, :greenhouse,
        :native_sophont, :sophont_id, :new_sophont_name, :extinct_sophont, :habitability_rating, :biomass_rating,
        :biodiversity_rating, :biocomplexity_rating, :compatibility_rating, :resource_rating,
        *uwp_attribute_names
      ]
    end
  end
end
