# frozen_string_literal: true

class SocialCharacteristicsPreset < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  scope :ordered, -> { order(:name) }
end
