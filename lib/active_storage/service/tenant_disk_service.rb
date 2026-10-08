# frozen_string_literal: true

require 'active_storage/service/disk_service'

module ActiveStorage
  # Disk service that namespaces files by tenant, then by file type:
  #   <root>/<tenant_key>/<subdirectory>/<xx>/<yy>/<key>
  #
  # The tenant is resolved on every call because the service is built once at boot.
  # The tenant key is opaque (see Campaign#storage_key) so folder names cannot be
  # used to enumerate other campaigns.
  class Service::TenantDiskService < Service::DiskService
    def initialize(subdirectory:, **options)
      super(**options)
      @subdirectory = subdirectory
    end

    private

    def folder_for(key)
      [tenant_key, @subdirectory, super].join('/')
    end

    def tenant_key
      tenant = Apartment::Tenant.current
      return tenant if tenant == 'public'

      Campaign.find_by!(schema_name: tenant).storage_key
    end
  end
end
