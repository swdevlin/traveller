# frozen_string_literal: true

class JobQueueStatus
  def self.pending_count(campaign_id: nil)
    SolidQueue::Record.transaction(requires_new: true) do
      if campaign_id
        campaign_jobs = SolidQueue::Job.where(
          "json_extract(arguments, '$.campaign_id') = ?", campaign_id
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
