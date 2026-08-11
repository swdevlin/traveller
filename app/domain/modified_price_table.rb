# frozen_string_literal: true

# Fixed lookup for the Modified Price table (Mongoose Traveller 2e Core Rulebook,
# p.243) — a modified 3D roll (with DMs already applied) looked up here gives the
# Purchase/Sale price as a percentage of a good's Base Price. Not campaign-overridable,
# same category as FreightTrafficTable/PassengerTrafficTable.
module ModifiedPriceTable
  PERCENT_BY_ROLL = {
    -3 => { purchase: 300, sale: 10 },
    -2 => { purchase: 250, sale: 20 },
    -1 => { purchase: 200, sale: 30 },
    0  => { purchase: 175, sale: 40 },
    1  => { purchase: 150, sale: 45 },
    2  => { purchase: 135, sale: 50 },
    3  => { purchase: 125, sale: 55 },
    4  => { purchase: 120, sale: 60 },
    5  => { purchase: 115, sale: 65 },
    6  => { purchase: 110, sale: 70 },
    7  => { purchase: 105, sale: 75 },
    8  => { purchase: 100, sale: 80 },
    9  => { purchase: 95,  sale: 85 },
    10 => { purchase: 90,  sale: 90 },
    11 => { purchase: 85,  sale: 100 },
    12 => { purchase: 80,  sale: 105 },
    13 => { purchase: 75,  sale: 110 },
    14 => { purchase: 70,  sale: 115 },
    15 => { purchase: 65,  sale: 120 },
    16 => { purchase: 60,  sale: 125 },
    17 => { purchase: 55,  sale: 130 },
    18 => { purchase: 50,  sale: 140 },
    19 => { purchase: 45,  sale: 150 },
    20 => { purchase: 40,  sale: 160 },
    21 => { purchase: 35,  sale: 175 },
    22 => { purchase: 30,  sale: 200 },
    23 => { purchase: 25,  sale: 250 },
    24 => { purchase: 20,  sale: 300 },
    25 => { purchase: 15,  sale: 400 }
  }.freeze

  # @param roll [Integer] the modified 3D roll
  # @return [Integer] Purchase price as a percentage of Base Price
  def self.purchase_percent(roll)
    PERCENT_BY_ROLL.fetch(roll.clamp(-3, 25))[:purchase]
  end

  # @param roll [Integer] the modified 3D roll
  # @return [Integer] Sale price as a percentage of Base Price
  def self.sale_percent(roll)
    PERCENT_BY_ROLL.fetch(roll.clamp(-3, 25))[:sale]
  end
end
