class StarSystem < ApplicationRecord
  validates :parsec, presence: true
  has_many :stellar_objects, dependent: :destroy
  belongs_to :parsec
end
