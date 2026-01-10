# frozen_string_literal: true

require 'test_helper'

class RollTableTest < ActiveSupport::TestCase
  setup do
    @roller = DiceRoller.new

    table = {
      2 => 'low',
      3 => 'medium low',
      4 => 'medium',
      5 => 'medium high',
      6 => 'high'
    }
    @roll_table = RollTable.new(table: table, dice: 1, size: 6)

    table = {
      2 => 'low',
      3 => 'medium low',
      4 => ->(the_roll:, **_) { "medium (rolled #{the_roll})" },
      5 => 'medium high',
      6 => 'high'
    }
    @lambda_table = RollTable.new(table: table, dice: 1, size: 6)

    table = {
      1..3 => 'low',
      4..8 => 'middle',
      9..10 => 'high'
    }
    @range_table = RollTable.new(table: table, dice: 1, size: 10)
  end

  test 'records a note that defaults to the class name' do
    @roll_table.roll(dm: 0, roller: @roller)
    assert_equal 'roll table', @roller.log.last[:note]
  end

  test 'roll less than min is min' do
    r = @roll_table.roll(the_roll: 1, dm: 0, roller: @roller)
    assert_equal 'low', r
  end

  test 'table lookup' do
    r = @roll_table.roll(the_roll: 4, dm: 0, roller: @roller)
    assert_equal 'medium', r
  end

  test 'roll greater than max is max' do
    r = @roll_table.roll(the_roll: 19, dm: 0, roller: @roller)
    assert_equal 'high', r
  end

  test 'lambda called' do
    r = @lambda_table.roll(the_roll: 4, dm: 0, roller: @roller)
    assert_equal 'medium (rolled 4)', r
  end

  test 'ranges supported' do
    r = @range_table.roll(the_roll: 4, dm: 0, roller: @roller)
    assert_equal 'middle', r
  end

  test 'ranges can be at the edges' do
    r = @range_table.roll(the_roll: -2, dm: 0, roller: @roller)
    assert_equal 'low', r

    r = @range_table.roll(the_roll: 22, dm: 0, roller: @roller)
    assert_equal 'high', r
  end
end
