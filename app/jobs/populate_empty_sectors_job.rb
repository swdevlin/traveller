# frozen_string_literal: true

class PopulateEmptySectorsJob < ApplicationJob
  queue_as :default

  def perform
    populated_sector_ids = Sector.joins(parsecs: :star_systems).select(:id)
    empty_sector_ids = Sector.kept.where.not(id: populated_sector_ids).select(:id)

    Subsector.where(sector_id: empty_sector_ids).where.not(build: nil).each do |subsector|
      sector = subsector.sector
      GenerateSubsectorJob.set(priority: job_priority(sector, subsector)).perform_later(subsector.id, subsector.build)
    end
  end

  private

  def job_priority(sector, subsector)
    sector.x.abs * 1000 + sector.y.abs * 10 + subsector.y + subsector.x
  end
end
