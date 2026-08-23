class Allegiance < ApplicationRecord
  include HasWorldStatistics
  include HasHexColour

  before_validation { self.background_colour = nil if background_colour.blank? }
  before_validation { self.border_colour     = nil if border_colour.blank? }

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates_hex_colour :background_colour, :border_colour, allow_nil: true

  has_many :stellar_objects, dependent: :nullify
  has_many :star_systems, dependent: :nullify

  # Touch associated star systems so subsector map caches are invalidated.
  # before_destroy runs before dependent: :nullify clears the association.
  before_destroy        { star_systems.touch_all }
  after_commit(on: :update) { star_systems.touch_all }

  def systems_scope
    star_systems
  end

  def worlds_scope
    StellarObject.where(star_system_id: systems_scope.select(:id), type: StellarObject::POPULATED_WORLD_TYPES).populated
  end
end
