# frozen_string_literal: true

# Fingerprint of everything that affects how a sector map renders. Shared by the
# SVG endpoint's cache key and the rasterised WebP so both invalidate together.
#
# Anything wholly inside the sector (parsecs, star systems, stellar objects,
# facilities) touches Sector#updated_at through belongs_to `touch: true`, so
# the sector's own timestamp covers it. Code that writes those records in bulk
# (update_all, delete_all, insert_all) skips callbacks and must touch the sector
# itself: Sector.where(id: ...).touch_all.
#
# Data that can span sectors (regions, jump routes, jump logs, survey overlays)
# has no single sector to touch, so it is still read with MAX queries.
class SectorMapVersion
  attr_reader :region_max_updated, :jump_max_updated

  def initialize(sector, campaign)
    @sector = sector
    @campaign = campaign
    load_timestamps
  end

  def digest
    Digest::SHA256.hexdigest(
      [
        @sector.updated_at.utc.iso8601(6),
        region_max_updated.to_i,
        jump_max_updated.to_i,
        @jump_route_link_max_updated.to_i,
        @jump_route_max_updated.to_i,
        @campaign.updated_at.to_i,
        HexMapBases::MAP_TEMPLATE_VERSION,
        SurveyOverlay.maximum(:updated_at).to_i,
        SurveyOverlay.count
      ].join('-')
    )
  end

  def last_modified
    [@sector.updated_at, region_max_updated, jump_max_updated].compact.max
  end

  private

  def load_timestamps
    system_ids = StarSystem.where(parsec_id: @sector.parsecs.select(:id)).select(:id)

    @region_max_updated = [
      RegionParsec.joins(:parsec).where(parsecs: { sector_id: @sector.id }).maximum(:updated_at),
      Region.joins(region_parsecs: :parsec).where(parsecs: { sector_id: @sector.id }).maximum(:updated_at)
    ].compact.max
    @jump_max_updated = JumpLog.maximum(:updated_at)
    @jump_route_link_max_updated = JumpRouteLink
      .where(from_star_system_id: system_ids, to_star_system_id: system_ids)
      .maximum(:updated_at)
    @jump_route_max_updated = JumpRoute
      .joins(:jump_route_links)
      .where(jump_route_links: { from_star_system_id: system_ids })
      .maximum(:updated_at)
  end
end
