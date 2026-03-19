require 'apartment/migrator'

class Campaign < ApplicationRecord
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

  store_accessor :settings, :tracks_survey_index, :sophont_check, :max_tech_level, :native_tech_level, :token_secret

  def tracks_survey_index?
    ActiveModel::Type::Boolean.new.cast(tracks_survey_index)
  end

  def max_tech_level_value
    max_tech_level.presence&.to_i || 16
  end

  def native_tech_level?
    ActiveModel::Type::Boolean.new.cast(native_tech_level)
  end

  before_create :set_tracks_survey_index
  before_create :set_sophont_check
  before_create :set_max_tech_level
  before_create :set_native_tech_level
  before_create :set_token_secret
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

  def token_for(path)
    OpenSSL::HMAC.hexdigest('SHA256', token_secret, path)
  end

  private

  def set_tracks_survey_index
    self.tracks_survey_index = deepnight_revelation?
  end

  def set_sophont_check
    self.sophont_check = charted_space? ? 'none' : 'standard'
  end

  def set_max_tech_level
    self.max_tech_level = 16
  end

  def set_native_tech_level
    self.native_tech_level = false
  end

  def set_token_secret
    self.token_secret = SecureRandom.hex(32)
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
