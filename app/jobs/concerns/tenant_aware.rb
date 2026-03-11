# frozen_string_literal: true

module TenantAware
  extend ActiveSupport::Concern

  private

  def broadcast_job_count(finishing: false)
    schema_name = Apartment::Tenant.current
    if schema_name != 'public'
      count = JobQueueStatus.pending_count(schema_name: schema_name)
      count -= 1 if finishing
      ActionCable.server.broadcast("jobs:#{schema_name}", { count: [count, 0].max })
    else
      super
    end
  end
end
