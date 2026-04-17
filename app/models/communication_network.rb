class CommunicationNetwork < ApplicationRecord
  validates :name, presence: true

  has_many :network_links, dependent: :destroy

  scope :ordered, -> { order(:name) }
end
