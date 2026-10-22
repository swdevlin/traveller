# frozen_string_literal: true

class JobQueueStatus
  # Housekeeping queues that should not show in the nav bar job counter.
  UNTRACKED_QUEUES = %w[sector_maps].freeze

  def self.pending_count(schema_name: nil)
    SolidQueue::Record.transaction(requires_new: true) do
      jobs = SolidQueue::Job.where.not(queue_name: UNTRACKED_QUEUES)
      jobs = jobs.where("json_extract(arguments, '$.tenant') = ?", schema_name) if schema_name

      SolidQueue::ReadyExecution.where(job_id: jobs.select(:id)).count +
        SolidQueue::ClaimedExecution.where(job_id: jobs.select(:id)).count
    end
  rescue ActiveRecord::StatementInvalid
    0
  end
end
