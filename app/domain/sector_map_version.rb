# frozen_string_literal: true

# Fingerprint of everything that affects how a sector map renders. Shared by the
# SVG endpoint's cache key and the rasterised WebP so both invalidate together.
class SectorMapVersion
  attr_reader :max_updated, :max_parsec_updated, :region_max_updated, :jump_max_updated

  def initialize(sector, campaign)
    @sector = sector
    @campaign = campaign
    load_timestamps
  end

  def digest
    Digest::SHA256.hexdigest(
      [
        @sector.updated_at.to_i,
        max_updated.to_i,
        max_parsec_updated.to_i,
        region_max_updated.to_i,
        jump_max_updated.to_i,
        @rogue_max_updated.to_i,
        @rogue_object_max_updated.to_i,
        @facility_max_updated.to_i,
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
    [@sector.updated_at, max_updated, max_parsec_updated, region_max_updated, jump_max_updated].compact.max
  end

  private

  def load_timestamps
    star_systems = StarSystem.joins(:parsec).where(parsecs: { sector_id: @sector.id })
    parsec_ids = @sector.parsecs.select(:id)
    system_ids = star_systems.select(:id)

    @max_updated = star_systems.maximum(:updated_at)
    @max_parsec_updated = @sector.parsecs.maximum(:updated_at)
    @region_max_updated = [
      RegionParsec.joins(:parsec).where(parsecs: { sector_id: @sector.id }).maximum(:updated_at),
      Region.joins(region_parsecs: :parsec).where(parsecs: { sector_id: @sector.id }).maximum(:updated_at)
    ].compact.max
    @jump_max_updated = JumpLog.maximum(:updated_at)
    @rogue_max_updated = StellarObject
      .where(parsec_id: parsec_ids, orbiting_id: nil)
      .where(type: %w[GasGiant Comet])
      .maximum(:updated_at)
    @rogue_object_max_updated = StellarObject
      .where(parsec_id: parsec_ids, orbiting_id: nil)
      .where.not(type: %w[GasGiant Comet Star])
      .maximum(:updated_at)
    @facility_max_updated = StarSystemFacility
      .joins(star_system: :parsec)
      .where(parsecs: { sector_id: @sector.id })
      .maximum(:updated_at)
    @jump_route_link_max_updated = JumpRouteLink
      .where(from_star_system_id: system_ids, to_star_system_id: system_ids)
      .maximum(:updated_at)
    @jump_route_max_updated = JumpRoute
      .joins(:jump_route_links)
      .where(jump_route_links: { from_star_system_id: system_ids })
      .maximum(:updated_at)
  end
end
