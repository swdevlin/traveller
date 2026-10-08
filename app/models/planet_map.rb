class PlanetMap < ApplicationRecord
  belongs_to :stellar_object

  has_one_attached :webp, service: :planet_maps, dependent: :purge_later

  validate :webp_attached

  def webp_data
    webp.download
  end

  private

  def webp_attached
    errors.add(:webp, :blank) unless webp.attached?
  end
end
