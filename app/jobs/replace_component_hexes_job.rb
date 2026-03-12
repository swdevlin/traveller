# frozen_string_literal: true

class ReplaceComponentHexesJob < ApplicationJob
  def perform(component_id, rows)
    component = RegionComponent.find(component_id)
    component.region_parsecs.delete_all

    parsec_ids = rows.filter_map do |row|
      ux = row[:sector_x] * 32 + (row[:hex_x] - 1)
      uy = row[:sector_y] * 40 - (row[:hex_y] - 1)
      Parsec.find_by(x: ux, y: uy)&.id
    end.uniq

    if parsec_ids.any?
      now = Time.current
      records = parsec_ids.map do |pid|
        { region_component_id: component.id, parsec_id: pid, kind: 'fill',
          created_at: now, updated_at: now }
      end
      RegionParsec.insert_all!(records)
    end

    RegionChannel.broadcast_to(component.region, { event: 'finished' })
  end
end
