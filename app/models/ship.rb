class Ship < ApplicationRecord
  has_many :jump_logs, dependent: :destroy

  validates :m_drive, numericality: { in: 0..10 }, allow_nil: true

  # The ship's most recent jump, which is where it currently is. Ordered by
  # sequence, as the jump log is, rather than by date.
  def last_jump
    self.class.last_jumps_for([self])[id]
  end

  # The most recent jump of each of the given ships, as { ship_id => JumpLog },
  # in one query. Ships that have not jumped are absent.
  def self.last_jumps_for(ships)
    JumpLog.where(ship_id: ships.map(&:id))
           .select('DISTINCT ON (ship_id) jump_logs.*')
           .order(:ship_id, sequence: :desc, id: :desc)
           .includes(from_parsec: :star_systems, to_parsec: :star_systems)
           .index_by(&:ship_id)
  end

  def to_s
    name
  end
end
