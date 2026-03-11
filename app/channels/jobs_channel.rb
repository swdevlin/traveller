# frozen_string_literal: true

class JobsChannel < ApplicationCable::Channel
  def subscribed
    schema_name = params[:schema_name].presence
    if schema_name
      stream_from "jobs:#{schema_name}"
      ActionCable.server.broadcast("jobs:#{schema_name}", { count: JobQueueStatus.pending_count(schema_name: schema_name) })
    else
      stream_from 'jobs'
      ActionCable.server.broadcast('jobs', { count: JobQueueStatus.pending_count })
    end
  end
end
