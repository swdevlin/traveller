# frozen_string_literal: true

# Default DM values for the Passenger Traffic procedure (Mongoose Traveller 2e,
# p.239), overridable per campaign since trade rules are heavily house-ruled.
# Overrides live on Campaign#settings as passenger_dm_<key> store_accessors.
module PassengerTrafficDms
  # Population digit ≤1 through 12, one DM per digit (index 0 = ≤1, index 1 = 2, ... index 11 = 12).
  # Only ≤1 (-4), 6-7 (+1) and 8+ (+3) are part of the original sourcebook design.
  POPULATION_DEFAULTS = [-4, 0, 0, 0, 0, 1, 1, 3, 3, 3, 3, 3].freeze

  DEFAULTS = {
    population: POPULATION_DEFAULTS,
    starport_a: 2,
    starport_b: 1,
    starport_c: 0, # Not in the original design
    starport_d: 0, # Not in the original design
    starport_e: -1,
    starport_x: -3,
    zone_amber: 1,
    zone_red: -4,
    high_passenger: -4, # Rolling for High passengers
    low_passenger: 1, # Rolling for Low passengers
    per_parsec: -1 # Each parsec of destination past the first
  }.freeze

  # @param campaign [Campaign, nil]
  # @return [Hash<Symbol, Integer|Array<Integer>>] resolved DM values, campaign
  #   overrides applied over the sourcebook defaults.
  def self.for(campaign)
    DEFAULTS.merge(overrides(campaign))
  end

  def self.overrides(campaign)
    return {} unless campaign

    DEFAULTS.each_key.with_object({}) do |key, result|
      value = campaign.public_send(:"passenger_dm_#{key}")
      next if value.blank?

      result[key] = key == :population ? merged_population(value) : value.to_i
    end
  end
  private_class_method :overrides

  def self.merged_population(value)
    Array(value).each_with_index.map { |v, i| v.presence ? v.to_i : POPULATION_DEFAULTS[i] }
  end
  private_class_method :merged_population
end
