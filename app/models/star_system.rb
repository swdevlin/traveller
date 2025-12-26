class StarSystem < ApplicationRecord
  validates :parsec, presence: true
  belongs_to :parsec
end
