module HexDigit

  HEX_DIGITS = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'.freeze

  def hex_digit(n)
    n = n.to_i
    n = [n, HEX_DIGITS.length - 1].min
    HEX_DIGITS[n]
  end

  module_function :hex_digit
end
