class Parsec < ApplicationRecord
  validates :x, :y, :sector, presence: true
  belongs_to :sector
  has_many :solar_systems, dependent: :destroy
  has_many :stellar_objects, dependent: :destroy

  validates :x, uniqueness: {
    scope: [:y, :sector_id],
    message: "parsec already exists"
  }

end
