# frozen_string_literal: true

module ColourHelper
  def border_colour_for(fill_hex)
    return nil if fill_hex.blank?

    rgb = hex_to_rgb(fill_hex)
    return nil unless rgb

    lum = relative_luminance(rgb)

    factor =
      if lum > 0.7
        0.55
      elsif lum > 0.4
        0.65
      else
        0.75
      end

    dark_rgb = {
      r: (rgb[:r] * factor).round,
      g: (rgb[:g] * factor).round,
      b: (rgb[:b] * factor).round
    }

    rgb_to_hex(dark_rgb)
  end

  private

  def hex_to_rgb(hex)
    s = hex.to_s.strip
    s = s.delete_prefix('#')
    return nil unless s.match?(/\A[\h]{6}\z/)

    {
      r: s[0..1].to_i(16),
      g: s[2..3].to_i(16),
      b: s[4..5].to_i(16)
    }
  end

  def rgb_to_hex(rgb)
    format('#%02x%02x%02x', rgb[:r].clamp(0, 255), rgb[:g].clamp(0, 255), rgb[:b].clamp(0, 255))
  end

  def relative_luminance(rgb)
    r = srgb_to_linear(rgb[:r] / 255.0)
    g = srgb_to_linear(rgb[:g] / 255.0)
    b = srgb_to_linear(rgb[:b] / 255.0)

    (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
  end

  def srgb_to_linear(c)
    c <= 0.04045 ? (c / 12.92) : (((c + 0.055) / 1.055)**2.4)
  end
end
