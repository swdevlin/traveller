require 'apartment/migrator'

class Campaign < ApplicationRecord
  belongs_to :referee, class_name: 'User'

  after_create :set_schema_name
  after_create_commit :create_tenant

  RESERVED_SLUGS = %w[
    www
    eric ericstevens catanach omicron radiofreewaba rfw shawn swd devlin shawndevlin
    deepnightrevelation dnr deepnight revelation drinax pod
  ].freeze

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
                   length: { minimum: 3, message: 'must be at least 3 characters' },
                   exclusion: { in: RESERVED_SLUGS, message: 'is reserved' },
                   format: { with: /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?\z/, message: 'must contain only lowercase letters, numbers, and hyphens, and cannot start or end with a hyphen' }

  private

  def set_schema_name
    update_column(:schema_name, "camp#{id}")
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
