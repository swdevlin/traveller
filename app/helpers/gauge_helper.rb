# frozen_string_literal: true

module GaugeHelper
  def gauge_position_percent(value, min:, max:)
    min = min.to_f
    max = max.to_f
    value = value.to_f.clamp(min, max)

    return 0 if max <= min

    (((value - min) / (max - min)) * 100).round(2)
  end
end
