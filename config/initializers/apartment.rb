# frozen_string_literal: true

#
# Apartment Configuration
#
Apartment.configure do |config|
  # Add any models that you do not want to be multi-tenanted, but remain in the global (public) namespace.
  config.excluded_models = %w[ User Campaign Session FontAwesomeIcon ]

  config.tenant_names = lambda do
    if ActiveRecord::Base.connection.data_source_exists?('campaigns')
      Campaign.pluck(:schema_name)
    else
      []
    end
  rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad
    []
  end

  # There are cases where you might want some schemas to always be in your search_path
  # e.g when using a PostgreSQL extension like hstore.
  config.persistent_schemas = %w[shared_extensions]
end

# Tenant switching is handled in ApplicationController via params[:campaign_slug].
# No middleware elevator is used.
