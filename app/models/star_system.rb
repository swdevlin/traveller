class StarSystem < ApplicationRecord
  normalizes *(attribute_names - %w[native_sophont extinct_sophont]), with: -> { it.presence }

  belongs_to :parsec
  belongs_to :main_world, class_name: 'StellarObject', optional: true
  belongs_to :allegiance, optional: true
  belongs_to :travel_zone, optional: true

  validates :parsec_id, presence: { message: 'You must select a hex' }

  has_many :stars, class_name: 'Star', foreign_key: :star_system_id, dependent: :destroy
  has_many :jump_route_links_as_from, class_name: 'JumpRouteLink', foreign_key: :from_star_system_id, dependent: :destroy
  has_many :jump_route_links_as_to, class_name: 'JumpRouteLink', foreign_key: :to_star_system_id, dependent: :destroy
  has_many :star_system_trade_codes, dependent: :destroy
  has_many :star_system_facilities, dependent: :destroy
  has_many :trade_codes, through: :star_system_trade_codes
  has_many :facilities, through: :star_system_facilities

  has_many :stellar_objects, through: :stars

  has_many :gas_giants, through: :stars, source: :stellar_objects, class_name: 'GasGiant'

  validate :main_world_must_be_in_system

  def ordered_stars
    stars.order(:orbit_sequence)
  end

  def table_description
    stars.map(&:spectral_classification).join(', ')
  end

  def age
    primary_star.age || ''
  end

  def trade_codes_string
    trade_codes.order(:code).pluck(:code).join(' ')
  end

  def facilities_string
    facilities.order(:code).pluck(:code).join(' ')
  end

  def primary_star
    @primary_star ||= stars.loaded? ? stars.find { |s| s.orbiting_id.nil? } : stars.find_by(orbiting_id: nil)
  end

  def orbiting_bodies
    bodies = primary_star.stellar_objects.to_a + primary_star.stars.to_a
    bodies.sort_by { |b| b.orbit.to_f }
  end

  def jump_route_links
    JumpRouteLink
      .where('from_star_system_id = ? OR to_star_system_id = ?', id, id)
      .includes(:jump_route, :from_star_system, :to_star_system)
  end

  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: [false, nil]) }

  scope :with_native_sophont, -> {
    where(id: StellarObject.where("stellar_objects.data @> '{\"native_sophont\": true}'").select(:star_system_id))
  }

  def has_gas_giant?
    gas_giant_count.to_i > 0
  end

  def has_populated_world?
    stellar_objects
      .where(type: %w[TerrestrialPlanet Moon PlanetoidBelt Planetoid])
      .where("(stellar_objects.data -> 'population' ->> 'code')::int > 0")
      .exists?
  end

  def recalculate_sophont_flags!
    recalculate_derived_fields!(sophont_flags: true)
  end

  def recalculate_world_counts!
    recalculate_derived_fields!(world_counts: true)
  end

  def recalculate_derived_fields!(world_counts: false, sophont_flags: false)
    attrs = {}

    if world_counts
      counts = stellar_objects.where(type: StellarObject::WORLD_COUNT_TYPES).group(:type).count
      attrs[:terrestrial_count] = counts.fetch('TerrestrialPlanet', 0)
      attrs[:belt_count]        = counts.fetch('PlanetoidBelt', 0)
      attrs[:gas_giant_count]   = counts.fetch('GasGiant', 0)
    end

    if sophont_flags
      attrs[:native_sophont]  = stellar_objects.where("stellar_objects.data @> '{\"native_sophont\": true}'").exists?
      attrs[:extinct_sophont] = stellar_objects.where("stellar_objects.data @> '{\"extinct_sophont\": true}'").exists?
    end

    update!(attrs) if attrs.any?
  end

  def main_world_uwp
    return nil if main_world_id.nil?

    @main_world_uwp ||= main_world&.uwp
  end

  def main_world_importance
    main_world.respond_to?(:importance) ? main_world.importance : nil
  end

  def main_world_wtn
    main_world.respond_to?(:world_trade_number) ? main_world.world_trade_number : nil
  end

  def pbg
    "#{HexDigit.hex_digit(terrestrial_count)}#{HexDigit.hex_digit(belt_count)}#{HexDigit.hex_digit(gas_giant_count)}"
  end

  def display_name
    return name if name.present?

    "#{parsec.sector.name} #{parsec.hex_code}"
  end

  private

  def main_world_must_be_in_system
    return unless main_world
    return if stellar_objects.exists?(id: main_world_id)
    return if Moon.exists?(star_system_id: id, id: main_world_id)

    errors.add(:main_world, 'must be in system')
  end
end
