# frozen_string_literal: true

require 'test_helper'

class PassengerTrafficTableTest < ActiveSupport::TestCase
  test 'roll of 1 or less yields no dice code' do
    assert_nil PassengerTrafficTable.dice_for(1)
    assert_nil PassengerTrafficTable.dice_for(0)
    assert_nil PassengerTrafficTable.dice_for(-5)
  end

  test 'every table row matches the sourcebook Passenger Traffic table' do
    expected = {
      2 => [1, 6], 3 => [1, 6],
      4 => [2, 6], 5 => [2, 6], 6 => [2, 6],
      7 => [3, 6], 8 => [3, 6], 9 => [3, 6], 10 => [3, 6],
      11 => [4, 6], 12 => [4, 6], 13 => [4, 6],
      14 => [5, 6], 15 => [5, 6],
      16 => [6, 6],
      17 => [7, 6],
      18 => [8, 6],
      19 => [9, 6],
      20 => [10, 6]
    }

    expected.each do |roll, dice|
      assert_equal dice, PassengerTrafficTable.dice_for(roll), "roll #{roll}"
    end
  end

  test 'rolls above 20 clamp to the 20 or more row' do
    assert_equal [10, 6], PassengerTrafficTable.dice_for(25)
    assert_equal [10, 6], PassengerTrafficTable.dice_for(100)
  end
end
