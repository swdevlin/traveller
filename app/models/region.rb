class Region < ApplicationRecord
  include HasWorldStatistics

  has_many :region_parsecs, dependent: :destroy
  has_many :parsecs, through: :region_parsecs
  has_many :sectors, -> { distinct }, through: :parsecs

  enum :source, {
    manual: 'manual',
    travellermap: 'travellermap'
  }, validate: true

  validates :name, presence: true
  validates :source, presence: true

  scope :player_visible, -> { where(player_visible: true) }
  scope :for_sector, ->(sector) {
    joins(:parsecs).where(parsecs: { sector_id: sector.id }).distinct
  }

  def to_s
    name || 'Unnamed Region'
  end

  def imported?
    source == 'travellermap'
  end

  def manual?
    source == 'manual'
  end

  def contains_parsec?(parsec)
    region_parsecs.exists?(parsec: parsec, kind: 'fill')
  end

  def touches_parsec?(parsec)
    region_parsecs.exists?(parsec: parsec)
  end

  def label_sector_and_hex
    return nil unless label_x && label_y

    sector = sectors.find do |s|
      hx = label_x - s.x * 32 + 1
      hy = s.y * 40 - label_y + 1
      hx.between?(1, 32) && hy.between?(1, 40)
    end
    return nil unless sector

    hx = label_x - sector.x * 32 + 1
    hy = sector.y * 40 - label_y + 1
    [sector, hx, hy]
  end

  def label_parsec
    return nil unless label_x && label_y

    Parsec.find_by(x: label_x, y: label_y)
  end

  def border_parsecs_ordered
    region_parsecs.where(kind: 'border').order(:position)
  end

  def fill_parsecs
    region_parsecs.where(kind: 'fill')
  end

  def systems_scope
    StarSystem.where(parsec_id: region_parsec_ids)
  end

  def worlds_scope
    StellarObject.where(star_system_id: systems_scope.select(:id), type: StellarObject::POPULATED_WORLD_TYPES).populated
  end

  # All worlds per allegiance (uninhabited included), with the populated subset noted alongside.
  def allegiance_world_counts
    all_worlds = StellarObject.where(star_system_id: systems_scope.select(:id), type: StellarObject::POPULATED_WORLD_TYPES)
    totals     = all_worlds.where.not(allegiance_id: nil).group(:allegiance_id).count
    populated  = all_worlds.populated.where.not(allegiance_id: nil).group(:allegiance_id).count

    totals.keys.index_with { |id| { total: totals[id], populated: populated.fetch(id, 0) } }
  end

  private

  def region_parsec_ids
    region_parsecs.pluck(:parsec_id)
  end
end
