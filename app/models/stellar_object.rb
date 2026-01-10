require 'set'

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
  has_many :stellar_object_trade_codes, dependent: :destroy
  has_many :trade_codes, through: :stellar_object_trade_codes

  after_save_commit :recalculate_star_system_world_counts_if_needed
  after_destroy_commit :recalculate_star_system_world_counts_after_destroy

  validate :parsec_or_star_system_required
  validates :type, inclusion: { in: STI_TYPES }

  validate :cannot_orbit_self
  validate :orbiting_cannot_create_cycle
  validate :orbiting_must_be_in_same_star_system

  has_many :stellar_objects,
           class_name: 'StellarObject',
           foreign_key: :orbiting_id,
           dependent: :destroy,
           inverse_of: :orbiting
  belongs_to :orbiting, class_name: 'StellarObject', optional: true, inverse_of: :stellar_objects

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

  def cannot_orbit_self
    return if orbiting_id.blank?
    errors.add(:orbiting_id, 'cannot orbit itself') if orbiting_id == id
  end

  def orbiting_cannot_create_cycle
    return if orbiting_id.blank?
    return if id.blank?

    current_id = orbiting_id
    seen = Set.new([id])

    while current_id.present?
      return errors.add(:orbiting_id, 'cannot create an orbit cycle') if seen.include?(current_id)

      seen.add(current_id)

      current_id = StellarObject.where(id: current_id).pick(:orbiting_id)
    end
  end

  def orbiting_must_be_in_same_star_system
    return if orbiting_id.blank? || star_system_id.blank?

    other_star_system_id = StellarObject.where(id: orbiting_id).pick(:star_system_id)
    return if other_star_system_id.blank?

    errors.add(:orbiting_id, 'must be in the same star system') if other_star_system_id != star_system_id
  end

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
    return if star_system.nil?
    return if star_system.destroyed?
    return if star_system.marked_for_destruction?
    star_system&.recalculate_world_counts!
  end
end
