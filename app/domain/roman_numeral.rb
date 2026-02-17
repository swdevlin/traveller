# frozen_string_literal: true

module RomanNumeral
  VALUES = [
    [1000, 'M'], [900, 'CM'], [500, 'D'], [400, 'CD'],
    [100, 'C'], [90, 'XC'], [50, 'L'], [40, 'XL'],
    [10, 'X'], [9, 'IX'], [5, 'V'], [4, 'IV'],
    [1, 'I']
  ].freeze

  def self.convert(number)
    return '' if number.nil? || number <= 0

    result = +''
    remainder = number

    VALUES.each do |value, numeral|
      while remainder >= value
        result << numeral
        remainder -= value
      end
    end

    result
  end
end
