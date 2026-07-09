# frozen_string_literal: true

class JobQueueStatus
  def self.pending_count(schema_name: nil)
    SolidQueue::Record.transaction(requires_new: true) do
      if schema_name
        campaign_jobs = SolidQueue::Job.where(
          "json_extract(arguments, '$.tenant') = ?", schema_name
        )
        SolidQueue::ReadyExecution.where(job_id: campaign_jobs.select(:id)).count +
          SolidQueue::ClaimedExecution.where(job_id: campaign_jobs.select(:id)).count
      else
        SolidQueue::ReadyExecution.count + SolidQueue::ClaimedExecution.count
      end
    end
  rescue ActiveRecord::StatementInvalid
    0
  end
end
