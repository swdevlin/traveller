class Facility < ApplicationRecord
  include FontAwesomeIconField

  has_many :star_system_facilities, dependent: :destroy
  has_many :star_systems, through: :star_system_facilities

  include TouchesStarSystems

  def affected_star_systems = star_systems

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
