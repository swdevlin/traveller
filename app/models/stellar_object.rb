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

  include ScrubsMailtoLinks
  include HasOrbit

  belongs_to :parsec, optional: true
  belongs_to :orbiting_star, class_name: 'Star', optional: true, inverse_of: :stellar_objects, touch: true

  has_many :stellar_object_trade_codes, dependent: :destroy
  has_many :trade_codes, through: :stellar_object_trade_codes

  before_validation :recalculate_orbit_derived_fields, if: :orbit_changed?
  after_save_commit :recalculate_star_system_world_counts_if_needed
  after_destroy_commit :recalculate_star_system_world_counts_after_destroy

  validates :type, inclusion: { in: STI_TYPES }
  validate :parsec_xor_orbiting_star_required

  belongs_to :allegiance, optional: true

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

  def self.permitted_params
    [:name, :notes]
  end

  def jump_shadow
    (diameter || 0) * 100
  end

  # Calculates the effective jump shadow distance in km, considering:
  # - The object's own jump shadow (100 × diameter)
  # - The orbiting star's jump shadow minus distance to it
  # - Any ancestor stars' jump shadows minus cumulative distance
  # Returns the maximum distance needed to clear all shadows
  def effective_jump_shadow_km
    return jump_shadow if orbiting_star.nil?

    shadows = []

    # Object's own jump shadow
    shadows << jump_shadow

    # Distance from object to its orbiting star (in km)
    object_distance_km = (au || 0) * StellarConstants::AU_TO_KM

    # Orbiting star's shadow minus object's distance from it
    star = orbiting_star
    cumulative_distance_km = object_distance_km
    star_shadow_remaining = (star.jump_shadow || 0) - object_distance_km
    shadows << star_shadow_remaining if star_shadow_remaining > 0

    # Walk up the star hierarchy
    while star.orbiting.present?
      # Add the star's distance from its parent
      cumulative_distance_km += (star.au || 0) * StellarConstants::AU_TO_KM
      star = star.orbiting

      # Calculate remaining shadow for this ancestor star
      ancestor_shadow_remaining = (star.jump_shadow || 0) - cumulative_distance_km
      shadows << ancestor_shadow_remaining if ancestor_shadow_remaining > 0
    end

    shadows.max || 0
  end

  def display_name
    return name if name.present?

    "Unnamed #{type_title}"
  end

  def type_title
    self.class.model_name.human
  end

  private

  def orbit_star_system
    orbiting_star&.star_system
  end

  def orbit_star_system_for_destroy
    return nil if orbiting_star.nil?
    return nil if orbiting_star.destroyed?
    return nil if orbiting_star.marked_for_destruction?
    orbiting_star.star_system
  end

  def recalculate_orbit_derived_fields
    self.au = OrbitToAu.convert(orbit)
    if orbiting_star&.hzco.present?
      self.effective_hzco_deviation = orbit - orbiting_star.hzco
    end
  end

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
