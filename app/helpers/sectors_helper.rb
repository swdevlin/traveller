module SectorsHelper
  include SubsectorsHelper

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

  def traveller_wiki_link(sector, campaign)
    url = safe_external_url(sector.effective_reference_url(campaign))
    return nil unless url

    link_to url,
            target: '_blank',
            rel: 'noopener',
            title: 'Reference',
            aria: { label: "#{sector.name} reference link" },
            class: 'text-slate-400 hover:text-traveller-red no-underline hover:underline transition-colors' do
      tag.i(class: 'fa-regular fa-book-open', aria: { hidden: true })
    end
  end
end
