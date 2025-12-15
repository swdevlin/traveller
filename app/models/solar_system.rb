class SolarSystem < ApplicationRecord
  validates :parsec, presence: true
  belongs_to :parsec
end
