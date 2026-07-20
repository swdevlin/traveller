class Parsec < ApplicationRecord
  include FontAwesomeIconField

  validates :x, :y, :sector, presence: true
  belongs_to :sector
  has_many :star_systems, dependent: :destroy
  has_many :stellar_objects, dependent: :destroy

  validates :x, uniqueness: {
    scope: [:y, :sector_id],
    message: 'parsec already exists'
  }

  scope :labeled, -> { where.not(label: [nil, '']) }

  def rogues
    StellarObject
      .where(parsec_id: id)
      .where(orbiting_id: nil)
  end

  def display_name
    "#{sector.name} (#{hex_code})"
  end

  def subsector
    ul = sector.upper_left
    hx = (x - ul.x)
    hy = (ul.y - y)
    sx, sy = subsector_xy_for_parsec(hx, hy)

    if sector.association(:subsectors).loaded?
      sector.subsectors.find { |s| s.x == sx && s.y == sy }
    else
      sector.subsectors.find_by(x: sx, y: sy)
    end
  end

  def subsector_xy_for_parsec(x, y)
    [(x / 8) + 1, (y / 10) + 1]
  end

  def self.hex_address_from_coords(parsec_x, parsec_y, sector_x, sector_y)
    hx = parsec_x - sector_x * 32 + 1
    hy = sector_y * 40 - parsec_y + 1
    format('%02d%02d', hx, hy)
  end

  def hex_code
    self.class.hex_address_from_coords(x, y, sector.x, sector.y)
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
