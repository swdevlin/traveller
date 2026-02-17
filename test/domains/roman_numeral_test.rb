# frozen_string_literal: true

require 'test_helper'

class RomanNumeralTest < ActiveSupport::TestCase
  test 'converts single digits' do
    assert_equal 'I', RomanNumeral.convert(1)
    assert_equal 'II', RomanNumeral.convert(2)
    assert_equal 'III', RomanNumeral.convert(3)
    assert_equal 'IV', RomanNumeral.convert(4)
    assert_equal 'V', RomanNumeral.convert(5)
    assert_equal 'VI', RomanNumeral.convert(6)
    assert_equal 'VII', RomanNumeral.convert(7)
    assert_equal 'VIII', RomanNumeral.convert(8)
    assert_equal 'IX', RomanNumeral.convert(9)
  end

  test 'converts tens' do
    assert_equal 'X', RomanNumeral.convert(10)
    assert_equal 'XIV', RomanNumeral.convert(14)
    assert_equal 'XIX', RomanNumeral.convert(19)
    assert_equal 'XX', RomanNumeral.convert(20)
    assert_equal 'XXX', RomanNumeral.convert(30)
  end

  test 'returns empty string for nil or zero' do
    assert_equal '', RomanNumeral.convert(nil)
    assert_equal '', RomanNumeral.convert(0)
    assert_equal '', RomanNumeral.convert(-1)
  end
end
