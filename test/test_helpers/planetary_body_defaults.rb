# The model requires the values the starmap decoder needs (see HasPlanetaryBodyAttributes). Most tests
# build bodies without caring about them, so fill neutral values before validation. A test of the
# validations themselves sets `skip_planetary_defaults = true` on the record.
module PlanetaryBodyDefaults
  REQUIRED_DEFAULTS = {
    inclination: 0, eccentricity: 0, axial_tilt: 0, albedo: 0,
    biomass_rating: 0, biocomplexity_rating: 0, biodiversity_rating: 0, compatibility_rating: 0, resource_rating: 2
  }.freeze

  attr_accessor :skip_planetary_defaults

  def self.included(base)
    base.before_validation :apply_planetary_defaults
  end

  private

  def apply_planetary_defaults
    return if skip_planetary_defaults

    REQUIRED_DEFAULTS.each { |attribute, value| public_send("#{attribute}=", value) if public_send(attribute).nil? }
  end
end
