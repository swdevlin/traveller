class StellarObject < ApplicationRecord
  STI_TYPES = %w[
    BrownDwarf
    Comet
    GasCloud
    GasGiant
    GravityAnomaly
    InterstellarWreck
    PhantomObject
    PlanetoidBelt
    Planetoid
    RadiationCloud
    Relic
    SpaceStation
    TerrestrialPlanet
    Star
    UnusualObject
  ].freeze

  belongs_to :parsec, optional: true
  belongs_to :star_system, optional: true
  belongs_to :orbiting, class_name: 'StellarObject', optional: true
  has_many :stellar_objects, class_name: 'StellarObject', foreign_key: :orbiting_id, dependent: :nullify

  validate :parsec_or_star_system_required
  validates :type, inclusion: { in: STI_TYPES }

  def self.allowed_data_keys
    []
  end

  def self.sti_class_for(type)
    return unless STI_TYPES.include?(type.to_s)

    type.to_s.safe_constantize
  end
  private

  def parsec_or_star_system_required
    return if parsec_id.present? || star_system_id.present?
    errors.add(:base, 'stellar object must belong to a parsec or star system')
  end
end
