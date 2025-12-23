class Parsec < ApplicationRecord
  validates :x, :y, :sector, presence: true
  belongs_to :sector
  has_many :solar_systems, dependent: :destroy
  has_many :stellar_objects, dependent: :destroy

  validates :x, uniqueness: {
    scope: [:y, :sector_id],
    message: 'parsec already exists'
  }

  def hex_code
    ul = sector.upper_left
    hx = (x - ul.x) + 1
    hy = (ul.y - y) + 1
    format('%02d%02d', hx, hy)
  end

  def subsector_hex_code
    ul = sector.upper_left
    hx = (x - ul.x).modulo(8) + 1
    hy = (ul.y - y).modulo(10) + 1
    format('%02d%02d', hx, hy)
  end

  def hex_code=(code)
    hx = code.to_s[0, 2].to_i
    hy = code.to_s[2, 2].to_i

    ul = sector.upper_left
    self.x = ul.x + (hx - 1)
    self.y = ul.y - (hy - 1)
  end
end
