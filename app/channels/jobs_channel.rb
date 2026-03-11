# frozen_string_literal: true

class JobsChannel < ApplicationCable::Channel
  def subscribed
    campaign_id = params[:campaign_id]&.to_i
    if campaign_id&.positive?
      stream_from "jobs:#{campaign_id}"
      ActionCable.server.broadcast("jobs:#{campaign_id}", { count: JobQueueStatus.pending_count(campaign_id: campaign_id) })
    else
      stream_from 'jobs'
      ActionCable.server.broadcast('jobs', { count: JobQueueStatus.pending_count })
    end
  end
end
