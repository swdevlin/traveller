class Allegiance < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  has_many :stellar_objects, dependent: :nullify
  has_many :star_systems, dependent: :nullify
end
