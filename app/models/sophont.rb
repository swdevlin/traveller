# An intelligent species native to one or more worlds. Stellar objects reference a sophont by
# id through their jsonb data (see HasSophont); tenant schemas scope these to the campaign.
class Sophont < ApplicationRecord
  PICTURE_TYPES = %w[image/png image/jpeg image/webp image/gif].freeze
  MAX_PICTURE_BYTES = 10.megabytes

  # Created for every new charted space campaign (see Campaign#create_tenant).
  DEFAULTS = {
    'Aslan' => 'aslan', 'Solomani' => 'solomani', 'Vargr' => 'arrghoun', 'Zhodani' => 'zdetl',
    "K'Kree" => nil, 'Darrian' => nil, 'Hiver' => nil, 'Vegan' => nil, 'Droyne' => 'oynprith',
    'Vilani' => 'imperium', 'Geonee' => nil, 'Suerrat' => nil, 'Dolphin' => nil, 'Orca' => nil,
    'Bwap' => nil, 'Za’tachk' => nil, 'Gurvin' => 'gurvin', 'Tezcat' => nil
  }.freeze
  DEFAULT_NAMES = DEFAULTS.keys.freeze

  include HasReferenceUrl

  belongs_to :home_system, class_name: 'StarSystem', optional: true

  has_one_attached :picture, service: :sophont_pictures, dependent: :purge_later

  normalizes :name, with: ->(name) { name.to_s.strip }
  normalizes :language, :referee_notes, :player_notes, :reference_url, with: -> { it.presence }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validate :language_is_known
  validate :reference_url_is_web_address
  validate :picture_is_acceptable

  scope :ordered, -> { order(Arel.sql('lower(sophonts.name)')) }

  def self.find_by_name(name)
    where('lower(name) = ?', name.to_s.strip.downcase).first
  end

  # Adds any default sophont not already present in the current tenant. Safe to repeat.
  def self.seed_defaults
    DEFAULTS.each { |name, language| create!(name: name, language: language) unless find_by_name(name) }
  end

  # Stellar objects whose native sophont is this one.
  def worlds
    StellarObject.where('data @> ?', { sophont_id: id }.to_json)
  end

  def in_use?
    worlds.exists?
  end

  private

  def language_is_known
    return if language.blank?
    return if language.to_sym.in?(WordGenerator.languages)

    errors.add(:language, 'is not a known language')
  end

  def default_reference_url
    "https://wiki.travellerrpg.com/#{ERB::Util.url_encode(name.tr(' ', '_'))}"
  end

  def reference_url_is_web_address
    return if reference_url.blank?

    uri = URI.parse(reference_url)
    errors.add(:reference_url, 'must be a web address (http or https)') unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:reference_url, 'is not a valid web address')
  end

  def picture_is_acceptable
    return unless picture.attached?

    errors.add(:picture, 'must be a PNG, JPEG, WebP or GIF image') unless picture.content_type.in?(PICTURE_TYPES)
    errors.add(:picture, "is too large (limit #{MAX_PICTURE_BYTES / 1.megabyte} MB)") if picture.byte_size > MAX_PICTURE_BYTES
  end
end
