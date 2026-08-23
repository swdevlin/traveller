class TravelZone < ApplicationRecord
  include HasHexColour

  validates :code,   presence: true, uniqueness: true
  validates :name,   presence: true
  validates_hex_colour :colour, presence: true

  has_many :star_systems, dependent: :nullify

  before_destroy :prevent_protected_deletion

  scope :ordered, -> { order(:name) }

  private

  def prevent_protected_deletion
    return unless protected?

    errors.add(:base, "'#{name}' is a protected travel zone and cannot be deleted.")
    throw :abort
  end
end
