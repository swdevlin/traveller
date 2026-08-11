# frozen_string_literal: true

# Default DM values for the Freight Traffic procedure (Mongoose Traveller 2e,
# p.239), overridable per campaign since trade rules are heavily house-ruled.
# Overrides live on Campaign#settings as freight_dm_<key> store_accessors.
module FreightTrafficDms
  # Population digit ≤1 through 12, one DM per digit (index 0 = ≤1, index 1 = 2, ... index 11 = 12).
  # Only ≤1 (-4), 6-7 (+2) and 8+ (+4) are part of the original sourcebook design.
  POPULATION_DEFAULTS = [-4, 0, 0, 0, 0, 2, 2, 4, 4, 4, 4, 4].freeze

  # Tech level digit 0 through 16, one DM per digit (index == digit). Only ≤6 (-1)
  # and 9+ (+2) are part of the original sourcebook design; a referee may still
  # override any individual digit.
  TECH_LEVEL_MAX      = 16
  TECH_LEVEL_DEFAULTS = [-1, -1, -1, -1, -1, -1, -1, 0, 0, 2, 2, 2, 2, 2, 2, 2, 2].freeze

  DEFAULTS = {
    population: POPULATION_DEFAULTS,
    tech_level: TECH_LEVEL_DEFAULTS,
    starport_a: 2,
    starport_b: 1,
    starport_c: 0, # Not in the original design
    starport_d: 0, # Not in the original design
    starport_e: -1,
    starport_x: -3,
    zone_amber: -2,
    zone_red: -6,
    major_cargo: -4, # Rolling for Major Cargo
    incidental_cargo: 2, # Rolling for Incidental Cargo
    per_parsec: -1 # Each parsec of destination past the first
  }.freeze

  ARRAY_KEYS = %i[population tech_level].freeze

  # @param campaign [Campaign, nil]
  # @return [Hash<Symbol, Integer|Array<Integer>>] resolved DM values, campaign
  #   overrides applied over the sourcebook defaults.
  def self.for(campaign)
    DEFAULTS.merge(overrides(campaign))
  end

  def self.overrides(campaign)
    return {} unless campaign

    DEFAULTS.each_key.with_object({}) do |key, result|
      value = campaign.public_send(:"freight_dm_#{key}")
      next if value.blank?

      result[key] = ARRAY_KEYS.include?(key) ? merged_array(value, DEFAULTS[key]) : value.to_i
    end
  end
  private_class_method :overrides

  def self.merged_array(value, defaults)
    Array(value).each_with_index.map { |v, i| v.presence ? v.to_i : defaults[i] }
  end
  private_class_method :merged_array
end
