require 'apartment/migrator'

class Campaign < ApplicationRecord
  include HasHexColour

  belongs_to :referee, class_name: 'User'

  enum :campaign_type, {
    homebrew: 'homebrew',
    charted_space: 'charted_space',
    deepnight_revelation: 'deepnight_revelation'
  }, default: 'charted_space'

  enum :sector_source, {
    traveller_map: 'traveller_map',
    deepnight_defaults: 'deepnight_defaults'
  }, prefix: :source

  PASSENGER_DM_SETTINGS = PassengerTrafficDms::DEFAULTS.keys.map { |key| :"passenger_dm_#{key}" }.freeze
  FREIGHT_DM_SETTINGS   = FreightTrafficDms::DEFAULTS.keys.map { |key| :"freight_dm_#{key}" }.freeze
  MAIL_DM_SETTINGS      = MailTrafficDms::DEFAULTS.keys.map { |key| :"mail_dm_#{key}" }.freeze

  HEX_SIZES = { 'small' => 30, 'medium' => 40, 'large' => 50 }.freeze

  # Where the Deepnight Revelation campaign's starting ship, the Revelation, is based.
  DEEPNIGHT_HOME_SECTOR = { x: -10, y: -2 }.freeze

  store_accessor :settings, :exploration, :sophont_check, :max_tech_level, :native_tech_level, :token_secret,
                            :allow_captive_government, :orbit_distance_display, :realisticStarDistribution,
                            :default_language, :date_format, :trade_good_base_prices,
                            :local_broker_level, :local_broker_fee_percentage,
                            :sector_capital_colour, :subsector_capital_colour, :hex_size,
                            :limited_main_world_eccentricity, :starting_sector_x, :starting_sector_y,
                            *PASSENGER_DM_SETTINGS, *FREIGHT_DM_SETTINGS, *MAIL_DM_SETTINGS

  def exploration?
    ActiveModel::Type::Boolean.new.cast(exploration)
  end

  def allow_captive_government?
    val = ActiveModel::Type::Boolean.new.cast(allow_captive_government)
    val.nil? ? true : val
  end

  def realistic_star_distribution?
    ActiveModel::Type::Boolean.new.cast(realisticStarDistribution)
  end

  def show_au?
    orbit_distance_display.presence != 'orbit_number'
  end

  def traveller_date_format?
    date_format.presence != 'iso'
  end

  def show_orbit_number?
    orbit_distance_display.presence == 'orbit_number'
  end

  def max_tech_level_value
    max_tech_level.presence&.to_i || 16
  end

  def local_broker_level_value
    local_broker_level.presence&.to_i || 2
  end

  def local_broker_fee_percentage_value
    local_broker_fee_percentage.presence&.to_f || 10
  end

  def hex_size_value
    HEX_SIZES.fetch(hex_size, HEX_SIZES.fetch('medium'))
  end

  def starting_sector
    if starting_sector_x.present? && starting_sector_y.present?
      Sector.kept.find_by(x: starting_sector_x.to_i, y: starting_sector_y.to_i) || Sector.kept.nearest_to_origin
    else
      Sector.kept.nearest_to_origin
    end
  end

  def starting_location
    sector = starting_sector
    sector ? [sector.centre_coordinate.x, sector.centre_coordinate.y] : [0, 0]
  end

  def native_tech_level?
    ActiveModel::Type::Boolean.new.cast(native_tech_level)
  end

  def limited_main_world_eccentricity?
    ActiveModel::Type::Boolean.new.cast(limited_main_world_eccentricity) || false
  end

  before_validation :default_sector_source
  before_create :set_defaults
  after_create :set_schema_name
  after_create_commit :create_tenant
  after_create_commit :enqueue_deepnight_setup, if: :deepnight_revelation?

  RESERVED_SLUGS = %w[
    www
    eric ericstevens catanach omicron radiofreewaba rfw shawn swd devlin shawndevlin
    deepnightrevelation dnr deepnight revelation drinax pod
  ].freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   length: { minimum: 3, message: 'must be at least 3 characters' },
                   exclusion: { in: RESERVED_SLUGS, message: 'is reserved' },
                   format: { with: /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?\z/, message: 'must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen' },
                   if: -> { new_record? || slug_changed? }
  validates_hex_colour :sector_capital_colour, :subsector_capital_colour, allow_blank: true
  validates :hex_size, inclusion: { in: HEX_SIZES.keys }, allow_blank: true
  validates :starting_sector_x, :starting_sector_y, numericality: { only_integer: true }, allow_blank: true

  def token_for(path)
    OpenSSL::HMAC.hexdigest('SHA256', token_secret, path)
  end

  # Opaque per-campaign folder name for stored files. Derived from the secret rather than
  # the slug or schema_name, which are guessable, and hashed so the secret is not exposed.
  def storage_key
    Digest::SHA256.hexdigest("storage:#{token_secret}")[0, 32]
  end

  private

  def default_sector_source
    return if sector_source.present?

    self.sector_source = 'traveller_map' if charted_space?
    self.sector_source = 'deepnight_defaults' if deepnight_revelation?
  end

  def set_defaults
    self.exploration            = deepnight_revelation? if exploration.nil?
    self.sophont_check          = if charted_space?
      'none'
    elsif deepnight_revelation?
      'rareEarth'
    else
      'standard'
    end
    self.max_tech_level         = 16
    self.native_tech_level      = false
    self.token_secret           = SecureRandom.hex(32)
    self.api_token              = SecureRandom.hex(32)
    self.allow_captive_government  = !deepnight_revelation?
    self.orbit_distance_display    = 'au'
    self.realisticStarDistribution = false
    self.date_format               = 'traveller'
    self.local_broker_level        = 2
    self.local_broker_fee_percentage = 10
    self.hex_size                  = 'medium'
    if deepnight_revelation?
      self.starting_sector_x = DEEPNIGHT_HOME_SECTOR[:x]
      self.starting_sector_y = DEEPNIGHT_HOME_SECTOR[:y]
    end
  end

  def set_schema_name
    update_column(:schema_name, "camp#{id}")
  end

  def enqueue_deepnight_setup
    Apartment::Tenant.switch(schema_name) do
      PopulateDeepnightCampaignJob.perform_later(id)
    end
  end

  def create_tenant
    Apartment.connection.execute("CREATE SCHEMA \"#{schema_name}\"")
    Apartment::Migrator.migrate(schema_name)
    Apartment::Tenant.switch(schema_name) do
      load Rails.root.join('db/seeds/tenant.rb')
      load Rails.root.join('db/seeds/sectors.rb') unless homebrew? || deepnight_revelation?
      if charted_space?
        Sophont.seed_defaults
        Tag.seed_nobility
      end
    end
  rescue StandardError => e
    Apartment::Tenant.drop(schema_name) rescue nil
    destroy
    raise e
  end
end
