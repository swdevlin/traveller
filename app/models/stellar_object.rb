require 'set'

class StellarObject < ApplicationRecord
  SIZE_CODES = %w[0 S 1 2 3 4 5 6 7 8 9 A B C D E F G H J K L M].freeze
  WORLD_COUNT_TYPES = %w[TerrestrialPlanet PlanetoidBelt GasGiant].freeze
  STI_TYPES = %w[
    Comet
    GasCloud
    GasGiant
    GravityAnomaly
    InterstellarWreck
    Moon
    PhantomObject
    PlanetoidBelt
    Planetoid
    RadiationCloud
    Relic
    Ring
    SpaceStation
    Star
    TerrestrialPlanet
    UnusualObject
  ].freeze

  include ScrubsMailtoLinks
  include HasOrbit

  attr_accessor :skip_import_callbacks

  normalizes *(attribute_names - %w[data build_log characteristics known]), with: -> { it.presence }
  before_validation { self.data ||= {} }

  before_validation :normalize_size_code

  belongs_to :parsec, optional: true
  belongs_to :orbiting, class_name: 'StellarObject', foreign_key: :orbiting_id, optional: true, touch: true
  belongs_to :star_system, optional: true

  has_many :stellar_object_trade_codes, dependent: :destroy
  has_many :trade_codes, through: :stellar_object_trade_codes

  before_save :inherit_star_system_from_orbiting, unless: -> { is_a?(Star) }
  before_validation :recalculate_orbit_derived_fields, if: -> { !skip_import_callbacks && orbit_changed? }
  after_save_commit :recalculate_star_system_derived_fields_if_needed, unless: :skip_import_callbacks
  after_destroy_commit :recalculate_star_system_derived_fields_after_destroy

  validates :type, inclusion: { in: STI_TYPES }
  validate :parsec_xor_orbiting_required
  validates :size_code, inclusion: { in: SIZE_CODES }, allow_nil: true

  belongs_to :allegiance, optional: true
  belongs_to :tidal_lock_target, class_name: 'StellarObject', optional: true

  has_many :moons, class_name: 'Moon', foreign_key: :orbiting_id


  BY_SIZE_SQL = Arel.sql("array_position(ARRAY['0','S','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','J','K','L','M']::text[], size_code)")

  scope :by_size, -> { order(BY_SIZE_SQL) }

  def size_description
    StellarObjectsHelper::SIZE_DESCRIPTIONS[size_code]
  end

  def size_int
    return nil if size_code == 'S'
    size_code.to_i(16)
  end

  def size_numeric
    return BigDecimal('0.5') if size_code == 'S'
    BigDecimal(size_int)
  end

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
    [:name, :notes, :language, :known]
  end

  validates :language, inclusion: { in: -> { WordGenerator.languages.map(&:to_s) }, allow_blank: true }

  def effective_language(campaign)
    language.presence || star_system&.effective_language(campaign) || campaign.default_language.presence
  end

  def jump_shadow
    (diameter || 0) * 100
  end

  def safe_jump_time
    return '0d 0w' if diameter.nil? || diameter <= 0
    kms     = 100.0 * diameter
    seconds = 2.0 * Math.sqrt(kms * 1000.0 / (4 * 9.8))
    watches = (seconds / (60.0 * 60 * 8)).ceil
    days    = watches / 3
    watches -= days * 3
    "#{days}d #{watches}w"
  end

  def effective_jump_shadow_km
    compute_effective_jump_shadow[:km]
  end

  def effective_jump_shadow_source
    compute_effective_jump_shadow[:source]
  end

  def display_name
    return name if name.present?

    "Unnamed #{type_title}"
  end

  def type_title
    self.class.model_name.human
  end

  private

  def compute_effective_jump_shadow
    @compute_effective_jump_shadow ||= begin
      return { km: jump_shadow, source: nil } if orbiting.nil?

      best = { km: jump_shadow, source: nil }

      object_distance_km = orbit_distance_from_parent_km
      star = orbiting
      cumulative_distance_km = object_distance_km

      star_remaining = (star.jump_shadow || 0) - object_distance_km
      best = { km: star_remaining, source: star } if star_remaining > best[:km]

      while star.orbiting.present?
        cumulative_distance_km += star.orbit_distance_from_parent_km
        star = star.orbiting
        ancestor_remaining = (star.jump_shadow || 0) - cumulative_distance_km
        best = { km: ancestor_remaining, source: star } if ancestor_remaining > best[:km]
      end

      best
    end
  end

  def orbit_star_system
    StarSystem.find_by(id: orbiting&.star_system_id)
  end

  def orbit_star_system_for_destroy
    return nil if orbiting.nil?
    return nil if orbiting.destroyed?
    return nil if orbiting.marked_for_destruction?
    StarSystem.find_by(id: orbiting.star_system_id)
  end

  def recalculate_orbit_derived_fields
    self.au = OrbitToAu.convert(orbit)
    hzco_source = orbiting.is_a?(Star) ? orbiting : orbiting&.orbiting
    if hzco_source&.hzco.present?
      reference_orbit = orbiting.is_a?(Star) ? orbit : orbiting.orbit
      self.effective_hzco_deviation = reference_orbit - hzco_source.hzco
    end
  end

  def parsec_xor_orbiting_required
    return if is_a?(Star)

    if parsec_id.present? && orbiting_id.present?
      errors.add(:base, 'Cannot have both parsec and orbiting')
    elsif parsec_id.blank? && orbiting_id.blank?
      errors.add(:base, 'Must have either parsec or orbiting')
    end
  end

  def recalculate_star_system_derived_fields_if_needed
    world_counts = type.in?(WORLD_COUNT_TYPES) && (saved_change_to_orbiting_id? || saved_change_to_type?)
    sophont_flags = respond_to?(:data) && saved_change_to_data? &&
                    data_before_last_save&.slice('native_sophont', 'extinct_sophont') != data&.slice('native_sophont', 'extinct_sophont')

    if world_counts || sophont_flags
      StarSystem.find_by(id: star_system_id)&.recalculate_derived_fields!(world_counts:, sophont_flags:)
    end

    return unless world_counts && saved_change_to_orbiting_id?

    old_star_id = saved_change_to_orbiting_id.first
    StarSystem.find_by(id: Star.where(id: old_star_id).pick(:star_system_id))&.recalculate_derived_fields!(world_counts: true)
  end

  def recalculate_star_system_derived_fields_after_destroy
    world_counts = type.in?(WORLD_COUNT_TYPES)
    sophont_flags = respond_to?(:data) && data&.slice('native_sophont', 'extinct_sophont')&.any? { |_, v| v }

    return if orbiting.nil? || orbiting.destroyed? || orbiting.marked_for_destruction?

    StarSystem.find_by(id: star_system_id)&.recalculate_derived_fields!(world_counts:, sophont_flags:)
  end

  def inherit_star_system_from_orbiting
    self.star_system_id = orbiting&.star_system_id
  end

  def normalize_size_code
    return if size_code.blank?
    self.size_code = size_code.strip.upcase
  end
end
