class PlanetMap < ApplicationRecord
  PICTURE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_PICTURE_BYTES = 10.megabytes

  belongs_to :stellar_object

  enum :source, { generated: 'generated', uploaded: 'uploaded' }

  has_one_attached :webp, service: :planet_maps, dependent: :purge_later

  validate :webp_attached

  def webp_data
    webp.download
  end

  # Error message for an uploaded file that cannot be used as a map, or nil when acceptable.
  def self.upload_error(upload)
    return 'Choose an image to upload.' if upload.blank?
    return 'Image must be a PNG, JPEG, WebP or GIF.' unless upload.content_type.in?(PICTURE_TYPES)
    return "Image is too large (limit #{MAX_PICTURE_BYTES / 1.megabyte} MB)." if upload.size > MAX_PICTURE_BYTES

    nil
  end

  private

  def webp_attached
    errors.add(:webp, :blank) unless webp.attached?
  end
end
