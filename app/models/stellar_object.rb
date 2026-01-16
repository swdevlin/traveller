require 'set'

class StellarObject < ApplicationRecord
  STI_TYPES = %w[
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
    UnusualObject
  ].freeze

  belongs_to :parsec, optional: true
  belongs_to :orbiting_star, class_name: 'Star', optional: true, inverse_of: :stellar_objects

  has_many :stellar_object_trade_codes, dependent: :destroy
  has_many :trade_codes, through: :stellar_object_trade_codes

  after_save_commit :recalculate_star_system_world_counts_if_needed
  after_destroy_commit :recalculate_star_system_world_counts_after_destroy

  validates :type, inclusion: { in: STI_TYPES }
  validate :parsec_xor_orbiting_star_required

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

  def parsec_xor_orbiting_star_required
    if parsec_id.present? && orbiting_star_id.present?
      errors.add(:base, 'Cannot have both parsec and orbiting star')
    elsif parsec_id.blank? && orbiting_star_id.blank?
      errors.add(:base, 'Must have either parsec or orbiting star')
    end
  end

  def recalculate_star_system_world_counts_if_needed
    return unless saved_change_to_orbiting_star_id? || saved_change_to_type?

    new_star_system = orbiting_star&.star_system
    new_star_system&.recalculate_world_counts!

    return unless saved_change_to_orbiting_star_id?

    old_star_id = saved_change_to_orbiting_star_id.first
    old_star_system = Star.find_by(id: old_star_id)&.star_system
    old_star_system&.recalculate_world_counts!
  end

  def recalculate_star_system_world_counts_after_destroy
    return if orbiting_star.nil?
    return if orbiting_star.destroyed?
    return if orbiting_star.marked_for_destruction?
    orbiting_star.star_system&.recalculate_world_counts!
  end
end
