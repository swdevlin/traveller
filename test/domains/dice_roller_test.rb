# frozen_string_literal: true

require 'test_helper'

class DiceRollerTest < ActiveSupport::TestCase
  setup do
    @roller = DiceRoller.new
  end

  test 'number of dice must be positive' do
    assert_raises(ArgumentError) do
      @roller.roll(n: -1, d: 6, notes: 'dice must be positive')
    end
  end

  test 'number of sides must be positive' do
    assert_raises(ArgumentError) do
      @roller.roll(n: 3, d: -1, notes: 'sides must be positive')
    end
  end

  test 'note is required' do
    assert_raises(ArgumentError) do
      @roller.roll(n: 3, d: 6)
    end
  end
end
