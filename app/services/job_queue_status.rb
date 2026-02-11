# frozen_string_literal: true

class JobQueueStatus
  def self.pending_count
    SolidQueue::ReadyExecution.count + SolidQueue::ClaimedExecution.count
  rescue ActiveRecord::StatementInvalid
    0
  end
end
