# frozen_string_literal: true

require 'test_helper'

class CultureTraitDmTest < ActiveSupport::TestCase
  # The rulebook's "Potential Cultural Trait DMs" table.
  TABLE = { 1 => 2, 2 => 2, 3 => 1, 5 => 1, 6 => 0, 8 => 0, 9 => 1, 11 => 1,
            12 => 2, 14 => 2, 15 => 3, 17 => 3, 18 => 4, 25 => 4 }.freeze

  test 'magnitude matches the rulebook table' do
    TABLE.each { |value, dm| assert_equal dm, CultureTraitDm.magnitude(value), "trait value #{value}" }
  end

  test 'signed is negative below the middle band and positive above it' do
    assert_equal(-2, CultureTraitDm.signed(2))
    assert_equal(-1, CultureTraitDm.signed(5))
    assert_equal 0, CultureTraitDm.signed(7)
    assert_equal 1, CultureTraitDm.signed(9)
    assert_equal 3, CultureTraitDm.signed(16)
  end

  test 'display and blanks' do
    assert_equal '±3', CultureTraitDm.display(16)
    assert_equal '±0', CultureTraitDm.display(7)
    assert_nil CultureTraitDm.display(nil)
    assert_nil CultureTraitDm.magnitude(nil)
  end
end
