# frozen_string_literal: true

class PopulateAllSectorsJob < ApplicationJob
  queue_as :default

  def perform
    Subsector.where.not(build: nil).each do |subsector|
      GenerateSubsectorJob.perform_later(subsector.id, subsector.build)
    end
  end
end
