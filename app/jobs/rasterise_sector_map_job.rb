# frozen_string_literal: true

# Deliberately not an ApplicationJob: this is housekeeping, so it must not feed
# the nav bar job counter. The queue is also excluded in JobQueueStatus.
class RasteriseSectorMapJob < ActiveJob::Base
  queue_as :sector_maps

  def perform(sector_id, version, svg_cache_key)
    svg = Rails.cache.read(svg_cache_key)
    return if svg.blank?

    sector = Sector.find_by(id: sector_id)
    return unless sector

    SectorMapImage.new(sector, version).write(svg)
  end
end
