class Star < StellarObject
  include GeneratorMappings

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

  # Brown dwarf spectral classes: take a numeric subtype like O/B/A/F/G/K/M
  # (e.g. 'L5'), but have no luminosity class.
  BROWN_DWARF_TYPES = %w[L T Y].freeze

  generator_data_map(
    stellar_class: 'stellarClass',
    stellar_type: 'stellarType',
    stellar_subtype: 'subtype',
    luminosity: 'luminosity',
    hzco: 'hzco',
    minimum_allowable_orbit: 'minimumAllowableOrbit',
    jump_shadow: 'jumpShadow',
    colour: 'colour',
    is_protostar: 'isProtostar',
    temperature: 'temperature',
    age: 'age',
    period: 'period',
    baseline: 'baseline',
    spread: 'spread',
    scan_points: 'scanPoints'
  )

  belongs_to :star_system, optional: true, touch: true
  belongs_to :companion, class_name: 'Star', foreign_key: :companion_id, optional: true

  has_many :stars,
           class_name: 'Star',
           foreign_key: :orbiting_id,
           dependent: :destroy

  has_many :stellar_objects,
           -> { where.not(type: 'Star') },
           foreign_key: :orbiting_id,
           dependent: :destroy

  has_many :primary_stellar_objects,
           -> { where.not(type: %w[Star Planetoid]) },
           class_name: 'StellarObject',
           foreign_key: :orbiting_id

  def secondary_stars
    companion_id ? stars.where.not(id: companion_id) : stars
  end

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
    moon_count_sql = Arel.sql(
      "(SELECT COUNT(*) FROM stellar_objects m WHERE m.type = 'Moon' AND m.orbiting_id = stellar_objects.id) AS moon_count"
    )
    bodies = primary_stellar_objects.select('stellar_objects.*', moon_count_sql).to_a + stars.to_a
    bodies.sort_by { |b| b.orbit.to_f }
  end

  def mapped_bodies
    orbiting_bodies
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
end
