class Subsector < ApplicationRecord
  include ClearableParsecs
  validates :x, :y, :sector, presence: true
  belongs_to :sector

  validates :x, uniqueness: {
    scope: [:y, :sector_id],
    message: "Subsector already exists"
  }

  def universal_coordinates
    ul,  = sector.universal_coordinates
    ul = ul.dup
    ul.x += (x-1)* 8
    ul.y -= (y-1) * 10
    lr = Coordinate.new(x: ul.x+7, y: ul.y-9)
    return ul, lr
  end

  def parsecs
    ul, lr = universal_coordinates
    Parsec.where(x: ul.x..lr.x, y: lr.y..ul.y)
  end

  def wiki_link
    "https://wiki.travellerrpg.com/#{name.tr(' ', '_')}_Subsector"
  end

end
