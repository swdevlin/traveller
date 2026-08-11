# frozen_string_literal: true

# Default DM values for the Mail procedure (Mongoose Traveller 2e, p.239),
# overridable per campaign since trade rules are heavily house-ruled.
# Overrides live on Campaign#settings as mail_dm_<key> store_accessors.
#
# Mail is a special form of freight: its qualifying roll is keyed off the
# Freight Traffic DM computed for the same pair of worlds (see MailCalculator),
# bucketed into five tiers.
module MailTrafficDms
  DEFAULTS = {
    freight_dm_very_low:  -2, # Freight Traffic DM -10 or less
    freight_dm_low:       -1, # Freight Traffic DM -9 to -5
    freight_dm_average:    0, # Freight Traffic DM -4 to +4
    freight_dm_high:       1, # Freight Traffic DM 5 to 9
    freight_dm_very_high:  2, # Freight Traffic DM 10 or more
    ship_armed:            2, # Travellers' ship is armed
    low_tech_world:       -4  # Origin world is TL 5 or less
  }.freeze

  # @param campaign [Campaign, nil]
  # @return [Hash<Symbol, Integer>] resolved DM values, campaign overrides
  #   applied over the sourcebook defaults.
  def self.for(campaign)
    DEFAULTS.merge(overrides(campaign))
  end

  def self.overrides(campaign)
    return {} unless campaign

    DEFAULTS.each_key.with_object({}) do |key, result|
      value = campaign.public_send(:"mail_dm_#{key}")
      next if value.blank?

      result[key] = value.to_i
    end
  end
  private_class_method :overrides
end
