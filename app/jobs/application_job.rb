class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  after_enqueue { broadcast_job_count }
  after_perform { broadcast_job_count(finishing: true) }

  private

  def broadcast_job_count(finishing: false)
    count = JobQueueStatus.pending_count
    count -= 1 if finishing
    ActionCable.server.broadcast('jobs', { count: [count, 0].max })
  end
end
