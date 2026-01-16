module JobQueueHelper
  def pending_job_count
    SolidQueue::ReadyExecution.count + SolidQueue::ClaimedExecution.count
  rescue ActiveRecord::StatementInvalid
    0
  end
end
