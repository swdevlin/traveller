# frozen_string_literal: true

module OrbitToAu
  TABLE = [
    0,
    0.4, 0.7, 1.0, 1.6, 2.8, 5.2, 10, 20, 40, 77,
    154, 308, 615, 1230, 2500, 4900, 9800, 19500, 39500, 78700
  ].freeze

  def self.convert(orbit)
    return nil if orbit.nil?
    return TABLE[20] if orbit == 20

    if orbit > 20
      return TABLE[20] + (orbit - 20) * (TABLE[20] - TABLE[19])
    end

    o = orbit.truncate
    d = orbit - o
    TABLE[o] + (TABLE[o + 1] - TABLE[o]) * d
  end
end
