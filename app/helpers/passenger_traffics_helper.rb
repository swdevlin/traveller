# frozen_string_literal: true

module PassengerTrafficsHelper
  def passenger_roll_description(roll)
    "#{roll[:dice]}D#{roll[:sides]}#{format('%+d', roll[:dm]) if roll[:dm] != 0} " \
      "[#{roll[:rolls].join(', ')}] = #{roll[:total]}"
  end

  def passenger_modifier_description(modifier)
    "#{modifier[:label]} (#{format('%+d', modifier[:value])})"
  end
end
