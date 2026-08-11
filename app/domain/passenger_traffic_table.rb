# frozen_string_literal: true

# Fixed 2D lookup for the Passenger Traffic table (Mongoose Traveller 2e, p.239).
# A qualifying 2D roll (with modifiers) is looked up here to find the dice code
# rolled to determine the actual number of passengers available.
module PassengerTrafficTable
  DICE_BY_ROLL = {
    1  => nil,
    2  => [1, 6],
    3  => [1, 6],
    4  => [2, 6],
    5  => [2, 6],
    6  => [2, 6],
    7  => [3, 6],
    8  => [3, 6],
    9  => [3, 6],
    10 => [3, 6],
    11 => [4, 6],
    12 => [4, 6],
    13 => [4, 6],
    14 => [5, 6],
    15 => [5, 6],
    16 => [6, 6],
    17 => [7, 6],
    18 => [8, 6],
    19 => [9, 6],
    20 => [10, 6]
  }.freeze

  # @param roll [Integer] the qualifying 2D roll (with modifiers already applied)
  # @return [Array(Integer, Integer), nil] [n, d] dice code to roll for the passenger
  #   count, or nil when the row yields 0 passengers.
  def self.dice_for(roll)
    DICE_BY_ROLL.fetch(roll.clamp(1, 20))
  end
end
