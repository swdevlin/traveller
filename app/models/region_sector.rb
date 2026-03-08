class RegionSector < ApplicationRecord
  belongs_to :region
  belongs_to :sector

  validates :sector_id, uniqueness: { scope: :region_id }
end
