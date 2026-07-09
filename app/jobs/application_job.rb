class ApplicationJob < ActiveJob::Base
  before_enqueue { @broadcast_schema_name = Apartment::Tenant.current.presence }
  after_enqueue { broadcast_job_count(@broadcast_schema_name) }
  after_perform { broadcast_job_count(@broadcast_schema_name || Apartment::Tenant.current.presence, completing: true) }

  private

  def broadcast_job_count(schema_name, completing: false)
    count = JobQueueStatus.pending_count(schema_name: schema_name.presence)
    count = [count - 1, 0].max if completing

    if schema_name.present?
      ActionCable.server.broadcast("jobs:#{schema_name}", { count: count })
    else
      ActionCable.server.broadcast('jobs', { count: count })
    end
  end
end
