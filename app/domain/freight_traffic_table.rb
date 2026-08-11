# frozen_string_literal: true

# Fixed 2D lookup for the Freight Traffic table (Mongoose Traveller 2e, p.239).
# A qualifying 2D roll (with modifiers) is looked up here to find the dice code
# rolled to determine the number of cargo lots available.
module FreightTrafficTable
  DICE_BY_ROLL = {
    1  => nil,
    2  => [1, 6],
    3  => [1, 6],
    4  => [2, 6],
    5  => [2, 6],
    6  => [3, 6],
    7  => [3, 6],
    8  => [3, 6],
    9  => [4, 6],
    10 => [4, 6],
    11 => [4, 6],
    12 => [5, 6],
    13 => [5, 6],
    14 => [5, 6],
    15 => [6, 6],
    16 => [6, 6],
    17 => [7, 6],
    18 => [8, 6],
    19 => [9, 6],
    20 => [10, 6]
  }.freeze

  # @param roll [Integer] the qualifying 2D roll (with modifiers already applied)
  # @return [Array(Integer, Integer), nil] [n, d] dice code to roll for the lot
  #   count, or nil when the row yields 0 lots.
  def self.dice_for(roll)
    DICE_BY_ROLL.fetch(roll.clamp(1, 20))
  end
end
