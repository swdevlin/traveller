class Subsector < ApplicationRecord
  validates :x, :y, :sector, presence: true
  belongs_to :sector

  validates :x, uniqueness: {
    scope: [:y, :sector_id],
    message: "Subsector already exists"
  }

  def universal_coordinates
    ul, lr = sector.universal_coordinates
    ul.x += (x-1)* 8
    lr.x = ul.x + 8
    ul.y -= (y-i) * 10
    lr.y = ul.y + 10
    return ul, lr
  end

  def hexes
    ul, lr = universal_coordinates
    Parsec.where(x: ul.x..lr.x, y: ul.y..lr.y)
  end

  def wiki_link
    "https://wiki.travellerrpg.com/#{name.tr(' ', '_')}_Subsector"
  end

end
