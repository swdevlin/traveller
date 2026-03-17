# frozen_string_literal: true

class PopulateAllSectorsJob < ApplicationJob
  queue_as :default

  def perform
    Subsector
      .with_build
      .kept_sector
      .find_each do |subsector|
      sector = subsector.sector
      GenerateSubsectorJob
        .set(priority: job_priority(sector, subsector))
        .perform_later(subsector.id, subsector.build)
    end
  end

  def job_priority(sector, subsector)
    sector.x.abs * 1000 + sector.y.abs * 10 + subsector.y + subsector.x
  end
end
