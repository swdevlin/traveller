class ApplicationJob < ActiveJob::Base
  before_enqueue { @broadcast_schema_name = Apartment::Tenant.current.presence }
  after_enqueue { broadcast_job_count(@broadcast_schema_name) }
  after_perform { broadcast_job_count(@broadcast_schema_name || Apartment::Tenant.current.presence) }

  private

  def broadcast_job_count(schema_name)
    if schema_name.present?
      ActionCable.server.broadcast(
        "jobs:#{schema_name}",
        { count: JobQueueStatus.pending_count(schema_name: schema_name) }
      )
    else
      ActionCable.server.broadcast(
        'jobs',
        { count: JobQueueStatus.pending_count }
      )
    end
  end
end
