# frozen_string_literal: true

class NetworkLink < ApplicationRecord
  belongs_to :network
  belongs_to :from_star_system, class_name: 'StarSystem'
  belongs_to :to_star_system, class_name: 'StarSystem'

  before_validation :normalize_direction

  validates :from_star_system_id, uniqueness: { scope: :to_star_system_id, message: 'link already exists between these two systems' }
  validate :systems_must_differ

  def other_system(star_system)
    star_system.id == from_star_system_id ? to_star_system : from_star_system
  end

  private

  def normalize_direction
    return unless from_star_system_id && to_star_system_id
    return unless from_star_system_id > to_star_system_id

    self.from_star_system_id, self.to_star_system_id = to_star_system_id, from_star_system_id
  end

  def systems_must_differ
    return unless from_star_system_id && to_star_system_id

    errors.add(:base, 'A link cannot connect a system to itself') if from_star_system_id == to_star_system_id
  end
end
