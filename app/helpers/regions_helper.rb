module RegionsHelper
  def allegiance_histogram_bars(region, allegiances_by_id)
    region.allegiance_world_counts.filter_map do |allegiance_id, counts|
      allegiance = allegiances_by_id[allegiance_id]
      next unless allegiance

      {
        label: safe_join([tag.span(allegiance.code, class: 'identifier-sm'), allegiance.name].compact, ' '),
        href: allegiance_path(allegiance),
        count: counts[:total],
        sublabel: "#{counts[:populated]} populated"
      }
    end.sort_by { |bar| -bar[:count] }
  end
end
