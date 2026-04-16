class TravelZone < ApplicationRecord
  HEX_COLOUR_REGEX = /\A#[0-9a-fA-F]{6}\z/

  validates :code,   presence: true, uniqueness: true
  validates :name,   presence: true
  validates :colour, presence: true, format: { with: HEX_COLOUR_REGEX, message: 'must be a hex colour (#rrggbb)' }

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
