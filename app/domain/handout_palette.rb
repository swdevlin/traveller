# frozen_string_literal: true

# Colours for the printed handouts, taken from the viewer's theme. The page itself is always
# white, so the theme contributes its accent (the highlight colour, shared with OrbitMapTheme),
# darkened where needed to stay readable as small text on white, plus light tints of it.
module HandoutPalette
  WHITE = [255, 255, 255].freeze
  MIN_CONTRAST = 4.8

  # @param theme [String, nil] a theme name; unknown or blank falls back to the default theme
  # @return [Hash{Symbol => String}] :accent, :rule, :tint and :code as hex colours
  def self.for(theme)
    accent = readable_on_white(parse(OrbitMapTheme.palette(theme).highlight))
    {
      accent: to_hex(accent),
      rule: to_hex(mix(accent, WHITE, 0.78)),
      tint: to_hex(mix(accent, WHITE, 0.92)),
      code: to_hex(mix(accent, WHITE, 0.86))
    }
  end

  # Moves the colour towards black until it reaches MIN_CONTRAST against white.
  def self.readable_on_white(colour)
    amount = 0.0
    amount += 0.05 while contrast(mix(colour, [0, 0, 0], amount), WHITE) < MIN_CONTRAST && amount < 1.0
    mix(colour, [0, 0, 0], amount)
  end

  def self.parse(hex)
    hex.delete_prefix('#').scan(/../).map { |pair| pair.to_i(16) }
  end

  def self.to_hex(colour)
    format('#%02x%02x%02x', *colour)
  end

  # +weight+ of the second colour, from 0 to 1.
  def self.mix(first, second, weight)
    first.zip(second).map { |a, b| ((a * (1 - weight)) + (b * weight)).round }
  end

  # WCAG 2 relative luminance contrast ratio.
  def self.contrast(first, second)
    lighter, darker = [luminance(first), luminance(second)].sort.reverse
    (lighter + 0.05) / (darker + 0.05)
  end

  def self.luminance(colour)
    red, green, blue = colour.map do |channel|
      value = channel / 255.0
      value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
    end
    (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
  end
end
