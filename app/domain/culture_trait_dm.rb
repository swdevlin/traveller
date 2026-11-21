# frozen_string_literal: true

# The single source of truth for the "Potential Cultural Trait DMs" table.
# A trait value of 1-17 (18+ is possible in the rules) has a DM magnitude, and
# the sign depends on the trait's direction: below the middle (6-8) is
# negative, above it positive. Everything shown to users, the starmap API and
# the markdown export read from here; the starmap never recomputes it.
module CultureTraitDm
  # [highest trait value in the band, DM magnitude]
  BANDS = [[2, 2], [5, 1], [8, 0], [11, 1], [14, 2], [17, 3]].freeze
  OVERFLOW_MAGNITUDE = 4

  # @return [Integer, nil] 0 to 4, or nil without a value
  def self.magnitude(value)
    return nil if value.blank?

    BANDS.find { |highest, _| value.to_i <= highest }&.last || OVERFLOW_MAGNITUDE
  end

  # @return [Integer, nil] negative for low values (e.g. xenophobic), positive for high
  def self.signed(value)
    magnitude = magnitude(value)
    return nil if magnitude.nil?

    value.to_i < 6 ? -magnitude : magnitude
  end

  # @return [String, nil] e.g. '±2'
  def self.display(value)
    magnitude = magnitude(value)
    magnitude && "±#{magnitude}"
  end
end
