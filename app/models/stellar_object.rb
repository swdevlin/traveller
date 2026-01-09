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
  has_many :stellar_object_trade_codes, dependent: :destroy
  has_many :trade_codes, through: :stellar_object_trade_codes

  after_save_commit :recalculate_star_system_world_counts_if_needed
  after_destroy_commit :recalculate_star_system_world_counts_after_destroy

  validate :parsec_or_star_system_required
  validates :type, inclusion: { in: STI_TYPES }

  def trade_codes_string
    trade_codes.order(:code).pluck(:code).join(' ')
  end

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

  def recalculate_star_system_world_counts_if_needed
    return unless saved_change_to_star_system_id? || saved_change_to_type?

    star_system&.recalculate_world_counts!

    if saved_change_to_star_system_id?
      old_id = saved_change_to_star_system_id.first
      StarSystem.find_by(id: old_id)&.recalculate_world_counts!
    end
  end

  def recalculate_star_system_world_counts_after_destroy
    star_system&.recalculate_world_counts!
  end

end
