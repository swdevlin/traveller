class StellarObject < ApplicationRecord
  STI_TYPES = %w[
    Comet
    GasGiant
    BrownDwarf
    TerrestrialPlanet
    PlanetoidBelt
    InterstellarWreck
    ExtremelyUnusualObject
    Relic
    SpaceStation
    GasCloud
  ].freeze

  belongs_to :parsec, optional: true
  belongs_to :solar_system, optional: true
  belongs_to :parent, class_name: "StellarObject", optional: true

  validate :parsec_or_solar_system_required
  validates :type, inclusion: { in: STI_TYPES }

  private

  def parsec_or_solar_system_required
    return if parsec_id.present? || solar_system_id.present?
    errors.add(:base, "stellar object must belong to a parsec or solar system")
  end
end
