module TravellerHelper
  TRAVELLER_DIGITS = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ'.freeze

  def traveller_hex(value)
    return '' if value.nil?

    n = Integer(value)
    return '' if n.negative?

    return '0' if n.zero?

    base = TRAVELLER_DIGITS.length # 34
    out = +''
    while n.positive?
      n, rem = n.divmod(base)
      out.prepend(TRAVELLER_DIGITS[rem])
    end

    out
  rescue ArgumentError, TypeError
    ''
  end
end
