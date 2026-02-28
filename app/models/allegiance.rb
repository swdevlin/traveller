class Allegiance < ApplicationRecord
  HEX_COLOUR_REGEX = /\A#[0-9a-fA-F]{6}\z/

  before_validation { self.background_colour = nil if background_colour.blank? }
  before_validation { self.border_colour     = nil if border_colour.blank? }

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :background_colour, format: { with: HEX_COLOUR_REGEX }, allow_nil: true
  validates :border_colour,     format: { with: HEX_COLOUR_REGEX }, allow_nil: true

  has_many :stellar_objects, dependent: :nullify
  has_many :star_systems, dependent: :nullify

  # Touch associated star systems so subsector map caches are invalidated.
  # before_destroy runs before dependent: :nullify clears the association.
  before_destroy        { star_systems.touch_all }
  after_commit(on: :update) { star_systems.touch_all }
end
