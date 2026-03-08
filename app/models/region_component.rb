class RegionComponent < ApplicationRecord
  belongs_to :region
  belongs_to :source_sector, class_name: 'Sector', optional: true

  has_many :region_parsecs, dependent: :delete_all

  enum :input_type, {
    border_path: 'border_path',
    painted_parsecs: 'painted_parsecs'
  }, validate: true

  validates :input_type, presence: true

  scope :imported, -> { where.not(source_sector_id: nil) }
  scope :manual, -> { where(source_sector_id: nil) }

  def imported?
    source_sector_id.present?
  end

  def manual?
    source_sector_id.nil?
  end

  def border_parsecs
    region_parsecs.where(kind: 'border')
  end

  def fill_parsecs
    region_parsecs.where(kind: 'fill')
  end
end
