module SectorsHelper
  include SubsectorsHelper

  def sector_hex_grid_svg_dimensions
    width  = SVG_PADDING * 2 + 32 * HEX_WIDTH * 0.75 + HEX_WIDTH * 0.25
    height = SVG_PADDING * 2 + 40 * HEX_HEIGHT + HEX_HEIGHT * 0.5
    [width.round, height.round]
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
