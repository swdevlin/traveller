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

  store_accessor :settings, :exploration, :sophont_check, :max_tech_level, :native_tech_level, :token_secret,
                            :allow_captive_government, :orbit_distance_display, :realisticStarDistribution,
                            :default_language, :date_format, :trade_good_base_prices,
                            :local_broker_level, :local_broker_fee_percentage,
                            :sector_capital_colour, :subsector_capital_colour, :hex_size,
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

  def native_tech_level?
    ActiveModel::Type::Boolean.new.cast(native_tech_level)
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

  def token_for(path)
    OpenSSL::HMAC.hexdigest('SHA256', token_secret, path)
  end

  private

  def default_sector_source
    self.sector_source = 'traveller_map' if charted_space? && sector_source.blank?
  end

  def set_defaults
    self.exploration            = deepnight_revelation? if exploration.nil?
    self.sophont_check          = charted_space? ? 'none' : 'standard'
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
    end
  rescue StandardError => e
    Apartment::Tenant.drop(schema_name) rescue nil
    destroy
    raise e
  end
end
