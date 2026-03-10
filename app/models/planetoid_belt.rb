class PlanetoidBelt < StellarObject
  include GeneratorMappings
  include HasUwpAttributes

  before_validation :normalize_data_types

  validates :orbit, presence: true
  validate :orbit_above_minimum, if: -> { orbit.present? && orbiting.present? }
  validate :composition_sums_to_100
  validates :bulk, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_blank: true
  validates :resource_rating, numericality: { only_integer: true, in: 2..12 }, allow_blank: true
  validates :span, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  def self.permitted_params
    [
      :name, :notes, :orbit, :inclination, :eccentricity,
      *uwp_permitted_params,
      data: [:m_type, :s_type, :c_type, :o_type, :resource_rating, :bulk, :span,
             :temperature, :retrograde, :period]
    ]
  end

  def orbit_type = 12

  def significant_bodies
    Planetoid
      .where(star_system_id: star_system_id)
      .where("(data ->> 'planetoid_belt_id')::int = ?", id)
  end

  def diameter
    0
  end

  generator_data_map(
    m_type: 'mType',
    s_type: 'sType',
    c_type: 'cType',
    o_type: 'oType',
    resource_rating: 'resourceRating',
    bulk: 'bulk',
    span: 'span',
    temperature: 'meanTemperature',
    retrograde: 'retrograde',
    period: 'period',
    atmosphere: 'atmosphere',
    hydrographics: 'hydrographics',
    population: 'population',
    government_code: 'governmentCode',
    law_level_code: 'lawLevelCode',
    tech_level_code: 'techLevel',
    starport_code: 'starPort',
  )

  private

  def orbit_above_minimum
    min = orbiting.minimum_allowable_orbit
    if min.present? && orbit < min
      errors.add(:orbit, "must be at least #{min} (star's minimum allowable orbit)")
    end
  end

def normalize_data_types
    self.period = period.to_f if period.present?
    self.span = span.to_f if span.present?
    self.temperature = temperature.to_f if temperature.present?
    self.m_type = m_type.to_i if m_type.present?
    self.s_type = s_type.to_i if s_type.present?
    self.c_type = c_type.to_i if c_type.present?
    self.o_type = o_type.to_i if o_type.present?
    self.resource_rating = resource_rating.to_i if resource_rating.present?
    self.bulk = bulk.to_i if bulk.present?
  end

  def composition_sums_to_100
    values = [m_type, s_type, c_type, o_type].map(&:to_i)
    return if values.all?(&:zero?)

    unless values.sum == 100
      errors.add(:base, "Belt composition must total 100% (currently #{values.sum}%)")
    end
  end
end
