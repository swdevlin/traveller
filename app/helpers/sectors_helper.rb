module SectorsHelper
  include SubsectorsHelper

  def sector_hex_grid_svg_dimensions
    width  = SVG_PADDING * 2 + 32 * HEX_WIDTH * 0.75 + HEX_WIDTH * 0.25
    height = SVG_PADDING * 2 + 40 * HEX_HEIGHT + HEX_HEIGHT * 0.5
    [width.round, height.round]
  end

  def regions_for_map(parsec_scope, sector_ul, visible_hx:, visible_hy:)
    fill_rows = Region
      .joins(region_components: { region_parsecs: :parsec })
      .where(region_parsecs: { kind: 'fill' }, parsecs: { id: parsec_scope })
      .pluck('parsecs.x', 'parsecs.y', 'regions.colour')

    fills_by_hex = {}
    fill_rows.each do |px, py, colour|
      hx = px - sector_ul.x + 1
      hy = sector_ul.y - py + 1
      (fills_by_hex[format('%02d%02d', hx, hy)] ||= []) << { colour: colour }
    end

    label_rows = Region
      .where.not(label: [nil, ''])
      .where.not(label_x: nil)
      .joins(region_components: :region_parsecs)
      .where(region_parsecs: { parsec_id: parsec_scope })
      .distinct
      .pluck(:label, :label_x, :label_y, :colour, :label_colour)

    labels = label_rows.filter_map do |text, lx, ly, colour, label_colour|
      hx = lx - sector_ul.x + 1
      hy = sector_ul.y - ly + 1
      next unless visible_hx.include?(hx) && visible_hy.include?(hy)

      { hx: hx, hy: hy, text: text, colour: label_colour.presence || '#000000' }
    end

    [fills_by_hex, labels]
  end

  def sector_chart_link(sector)
    link_to map_sector_path(sector),
            target: '_blank',
            rel: 'noopener',
            title: 'Star chart',
            aria: { label: "#{sector.name} star chart" },
            class: 'text-slate-400 hover:text-traveller-red no-underline hover:underline transition-colors' do
      tag.i(class: 'fa-regular fa-telescope', aria: { hidden: true })
    end
  end

  def traveller_map_link(sector)
    link_to sector.traveller_map_url,
            target: '_blank',
            rel: 'noopener',
            title: 'Traveller Map',
            aria: { label: "#{sector.name} on Traveller Map" },
            class: 'text-slate-400 hover:text-traveller-red no-underline hover:underline transition-colors' do
      tag.i(class: 'fa-regular fa-map', aria: { hidden: true })
    end
  end

  def traveller_wiki_link(sector)
    link_to sector.wiki_link,
            target: '_blank',
            rel: 'noopener',
            title: 'Traveller Wiki',
            aria: { label: "#{sector.name} on Traveller Wiki" },
            class: 'text-slate-400 hover:text-traveller-red no-underline hover:underline transition-colors' do
      tag.i(class: 'fa-regular fa-book-open', aria: { hidden: true })
    end
  end
end
