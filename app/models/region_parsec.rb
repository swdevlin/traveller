class RegionParsec < ApplicationRecord
  belongs_to :region_component
  belongs_to :parsec

  enum :kind, {
    border: 'border',
    fill: 'fill'
  }, validate: true

  validates :kind, presence: true
  validates :parsec_id, uniqueness: { scope: %i[region_component_id kind] }

  delegate :region, to: :region_component
  delegate :sector, :x, :y, to: :parsec
end
