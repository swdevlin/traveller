class StatusController < ApplicationController
  def job_count
    count = SolidQueue::ReadyExecution.count + SolidQueue::ClaimedExecution.count
    render json: { count: count }
  end
end
