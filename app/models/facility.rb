class Facility < ApplicationRecord
  has_many :star_system_facilities, dependent: :destroy
  has_many :star_systems, through: :star_system_facilities

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
end
