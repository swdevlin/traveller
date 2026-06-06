# frozen_string_literal: true

module HexMapBases
  extend ActiveSupport::Concern

  MAP_TEMPLATE_VERSION = 4

  private

  def build_bases_data
    sys_ids = @systems_by_pos.values.map(&:id)
    @bases_by_pos = {}
    @facility_icons = {}
    @facility_names = {}
    return if sys_ids.empty?

    raw = StarSystemFacility
      .where(star_system_id: sys_ids)
      .joins(:facility)
      .pluck(:star_system_id, 'facilities.code')
    by_sys = raw.each_with_object({}) { |(sid, code), h| (h[sid] ||= []) << code }

    @bases_by_pos = @systems_by_pos.each_with_object({}) do |((col, row), sys), h|
      codes = by_sys[sys.id]
      h[[col, row]] = codes if codes
    end

    map_codes = @bases_by_pos.values.flatten.uniq
    facilities = Facility.where(code: map_codes).where.not(icon_class: [nil, ''])
    parsed = facilities.filter_map do |f|
      parts = f.icon_class.split(' ')
      { code: f.code, name: parts[1], style: parts[0].delete_prefix('fa-') }
    end

    return if parsed.empty?

    icons = FontAwesomeIcon
      .where(name: parsed.map { |p| p[:name] }.uniq)
      .index_by { |i| [i.name, i.style] }

    parsed.each do |p|
      icon = icons[[p[:name], p[:style]]]
      @facility_icons[p[:code]] = icon if icon
    end

    @facility_names = facilities
      .select { |f| @facility_icons.key?(f.code) }
      .each_with_object({}) { |f, h| h[f.code] = f.name }
  end
end
