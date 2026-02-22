class Star < ApplicationRecord
  SPECIAL_SPECTRAL_TYPES = {
    'BD' => 'Brown Dwarf',
    'D' => 'White Dwarf',
    'BH' => 'Black Hole',
    'PSR' => 'Pulsar',
    'NS' => 'Neutron Star',
    'NB' => 'Nebula',
    'PS' => 'Protostar',
    'AN' => 'Anomaly'
  }.freeze

  belongs_to :star_system, optional: true, touch: true
  belongs_to :parsec, optional: true

  belongs_to :companion, class_name: 'Star', optional: true
  belongs_to :orbiting, class_name: 'Star', optional: true

  has_many :stars,
           foreign_key: :orbiting_id,
           dependent: :destroy

  has_many :stellar_objects,
           foreign_key: :orbiting_star_id,
           inverse_of: :orbiting_star,
           dependent: :destroy

  include HasOrbit

  before_validation :recalculate_au, if: :orbit_changed?

  def display_name
    if name.present?
      "#{name} (#{spectral_classification})"
    else
      spectral_classification
    end
  end

  def spectral_classification
    if SPECIAL_SPECTRAL_TYPES.key?(stellar_type)
      SPECIAL_SPECTRAL_TYPES[stellar_type]
    else
      "#{stellar_type}#{stellar_subtype} #{stellar_class}"
    end
  end

  def orbiting_bodies
    bodies = stellar_objects.to_a + stars.to_a
    bodies.sort_by { |b| b.orbit.to_f }
  end

  # Returns the primary star (the one not orbiting anything)
  def primary_star
    current = self
    current = current.orbiting while current.orbiting.present?
    current
  end

  # Returns array of stars from this star up to (but not including) the primary
  # e.g., if this star orbits star B which orbits primary A, returns [B]
  def ancestor_stars
    ancestors = []
    current = orbiting
    while current.present?
      ancestors << current
      current = current.orbiting
    end
    ancestors
  end

  # Distance from the primary star in km
  def distance_from_primary_km
    return 0.0 if orbiting.nil? # This is the primary

    # Sum up AU distances through the chain and convert to km
    total_au = au.to_f
    current = orbiting
    while current.orbiting.present?
      total_au += current.au.to_f
      current = current.orbiting
    end
    total_au * StellarConstants::AU_TO_KM
  end

  def assign_data_from_generator(data)
    self.name = data['name']
    self.orbit_sequence = data['orbitSequence']
    self.orbit = data['orbit']
    self.stellar_class = data['stellarClass']
    self.stellar_type = data['stellarType']
    self.stellar_subtype = data['subtype']
    self.luminosity = data['luminosity']
    orbitPosition = data.fetch('orbitPosition', {})
    self.orbit_x = orbitPosition.fetch('x', nil)
    self.orbit_y = orbitPosition.fetch('y', nil)
    self.spread = data['spread']
    self.baseline = data['baseline']
    self.mass = data['mass']
    self.diameter = data['diameter']
    self.temperature = data['temperature']
    self.age = data['age']
    self.jump_shadow = data['jumpShadow']
    self.colour = data['colour']
    self.is_protostar = data['isProtostar']
    self.minimum_orbit = data['minimumOrbit']
    self.eccentricity = data['eccentricity']
    self.period = data['period']
    self.hzco = data['hzco']
    self.au = data['au']
    self.survey_index = data['surveyIndex']
    self.scan_points = data['scanPoints']
    self.build_log = data['buildLog']
  end

  private

  def orbit_star_system
    star_system || orbiting&.star_system
  end

  def orbit_star_system_for_destroy
    system = star_system || orbiting&.star_system
    return nil unless system
    return nil if system.destroyed?
    system
  end

  def recalculate_au
    self.au = OrbitToAu.convert(orbit)
  end
end
