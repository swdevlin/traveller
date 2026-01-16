class StatusController < ApplicationController
  include JobQueueHelper

  def job_count
    render json: { count: pending_job_count }
  end
end
