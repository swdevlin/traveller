# frozen_string_literal: true

class JobsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'jobs'
    ActionCable.server.broadcast('jobs', { count: JobQueueStatus.pending_count })
  end
end
