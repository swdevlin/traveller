class ImportRegionHexesJob < ApplicationJob
  def perform(region_id, rows)
    region = Region.find(region_id)

    rows.group_by { |r| [r[:sector_x], r[:sector_y]] }.each do |(sx, sy), hex_rows|
      sector = Sector.kept.find_by(x: sx, y: sy)
      next unless sector

      component = RegionComponent.find_or_create_by!(
        region:        region,
        source_sector: sector,
        input_type:    'painted_parsecs'
      )

      hex_rows.each do |row|
        ux = sx * 32 + (row[:hex_x] - 1)
        uy = sy * 40 - (row[:hex_y] - 1)

        parsec = Parsec.find_by(sector: sector, x: ux, y: uy)
        next unless parsec

        RegionParsec.find_or_create_by!(
          region_component: component,
          parsec:           parsec,
          kind:             'fill'
        )
      end
    end

    RegionChannel.broadcast_to(region, { event: 'finished' })
  end
end
