class Ship < ApplicationRecord
  has_many :jump_logs, dependent: :destroy

  validates :m_drive, numericality: { in: 0..10 }, allow_nil: true

  def to_s
    name
  end
end
