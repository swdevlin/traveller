# frozen_string_literal: true

module HexAddressing
  module_function

  def hex_address_from_coords(parsec_x, parsec_y, sector_x, sector_y)
    hx = parsec_x - sector_x * 32 + 1
    hy = sector_y * 40 - parsec_y + 1
    format('%02d%02d', hx, hy)
  end
end
