class StarSystem < ApplicationRecord
  belongs_to :parsec
  belongs_to :main_world, class_name: 'StellarObject', optional: true
  belongs_to :allegiance, optional: true

  has_many :stars, dependent: :destroy
  has_many :gas_giants, class_name: 'GasGiant'
  has_many :star_system_trade_codes, dependent: :destroy
  has_many :star_system_facilities, dependent: :destroy
  has_many :trade_codes, through: :star_system_trade_codes
  has_many :facilities, through: :star_system_facilities

  has_many :stellar_objects, through: :stars

  has_many :gas_giants, through: :stars, source: :stellar_objects, class_name: 'GasGiant'

  validate :main_world_must_be_in_system

  def table_description
    stars.map(&:spectral_classification).join(', ')
  end

  def trade_codes_string
    trade_codes.order(:code).pluck(:code).join(' ')
  end

  def facilities_string
    facilities.order(:code).pluck(:code).join(' ')
  end

  def primary_star
    @primary_star ||= stars.where(orbiting: nil).sole
  end

  def orbiting_bodies
    bodies = primary_star.stellar_objects.to_a + primary_star.stars.to_a
    bodies.sort_by { |b| b.orbit.to_f }
  end

  def has_gas_giant?
    @has_gas_giant ||= gas_giants.exists?
  end

  def main_world_uwp
    return nil if main_world_id.nil?

    @main_world_uwp ||= StellarObject.where(id: main_world_id).pick(:uwp)
  end

  def pbg
    "#{HexDigit.hex_digit(terrestrial_count)}#{HexDigit.hex_digit(belt_count)}#{HexDigit.hex_digit(gas_giant_count)}"
  end

  def recalculate_world_counts!
    counts = stellar_objects.group(:type).count

    update!(
      terrestrial_count: counts.fetch('TerrestrialPlanet', 0),
      belt_count: counts.fetch('PlanetoidBelt', 0),
      gas_giant_count: counts.fetch('GasGiant', 0)
    )
  end

  private

  def main_world_must_be_in_system
    return unless main_world
    return if stellar_objects.exists?(id: main_world_id)

    errors.add(:main_world, 'must be in system')
  end
end
