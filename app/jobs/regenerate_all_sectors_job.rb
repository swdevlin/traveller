# frozen_string_literal: true

class RegenerateAllSectorsJob < ApplicationJob
  queue_as :default

  def perform
    Subsector
      .with_build
      .kept_sector
      .find_each do |subsector|
      next if subsector_visited?(subsector)

      sector = subsector.sector
      GenerateSubsectorJob
        .set(priority: job_priority(sector, subsector))
        .perform_later(subsector.id, subsector.build)
    end
  end

  private

  def subsector_visited?(subsector)
    parsec_ids = subsector.parsec_scope.select(:id)
    JumpLog.where(from_parsec_id: parsec_ids).or(JumpLog.where(to_parsec_id: parsec_ids)).exists?
  end

  def job_priority(sector, subsector)
    sector.x.abs * 1000 + sector.y.abs * 10 + subsector.y + subsector.x
  end
end
