# frozen_string_literal: true

class JobQueueStatus
  def self.pending_count
    SolidQueue::Record.transaction(requires_new: true) do
      SolidQueue::ReadyExecution.count + SolidQueue::ClaimedExecution.count
    end
  rescue ActiveRecord::StatementInvalid
    0
  end
end
