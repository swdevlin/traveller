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

  # Ids of subsectors in the current tenant with a queued, scheduled or running
  # GenerateSubsectorJob. Failed jobs are excluded so the user is prompted again.
  def self.pending_subsector_ids(schema_name: Apartment::Tenant.current)
    SolidQueue::Record.transaction(requires_new: true) do
      job_ids =
        [SolidQueue::ReadyExecution, SolidQueue::ScheduledExecution, SolidQueue::ClaimedExecution]
          .flat_map { |execution| execution.pluck(:job_id) }

      SolidQueue::Job
        .where(id: job_ids, class_name: 'GenerateSubsectorJob', finished_at: nil)
        .where("json_extract(arguments, '$.tenant') = ?", schema_name.to_s)
        .pluck(Arel.sql("json_extract(arguments, '$.arguments[0]')"))
        .map(&:to_i)
    end
  rescue ActiveRecord::StatementInvalid
    []
  end
end
