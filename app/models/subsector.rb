class Subsector < ApplicationRecord
  validates :x, :y, :sector, presence: true
  belongs_to :sector

  validates :x, uniqueness: {
    scope: [:y, :sector_id],
    message: "Subsector already exists"
  }

  def wiki_link
    "https://wiki.travellerrpg.com/#{name.tr(' ', '_')}_Subsector"
  end

end
