class StarSystem < ApplicationRecord
  belongs_to :parsec
  has_many :stellar_objects, dependent: :destroy
  has_many :stars, class_name: 'Star'

  def table_description
    stars.map(&:spectral_classification).join(', ')
  end
end
