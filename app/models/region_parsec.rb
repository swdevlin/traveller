class RegionParsec < ApplicationRecord
  belongs_to :region
  belongs_to :parsec

  enum :kind, {
    border: 'border',
    fill: 'fill'
  }, validate: true

  validates :kind, presence: true
  validates :parsec_id, uniqueness: { scope: %i[region_id kind] }

  delegate :sector, :x, :y, to: :parsec
end
