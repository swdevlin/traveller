# Builds and caches a star's orbit map for the web and API controllers.
module OrbitMapRendering
  private

  # Each object links to its own page. The path is relative, so the SVG works wherever it is
  # opened from the same host and is the same for every request (and so cacheable).
  def orbit_map_link(object)
    object.is_a?(Star) ? star_path(object) : stellar_object_path(object)
  end

  def cached_orbit_map_svg(star, theme:, linked:)
    Rails.cache.fetch(orbit_map_cache_key(:svg, star, theme, linked)) do
      StarOrbitMap.new(star, theme: theme, link_builder: (method(:orbit_map_link) if linked), inline_images: true).to_svg
    end
  end

  # The webp is for sharing and downloading, so it has no links.
  def cached_orbit_map_webp(star, theme:)
    Rails.cache.fetch(orbit_map_cache_key(:webp, star, theme, false)) do
      SvgRasteriser.webp(StarOrbitMap.new(star, theme: theme, inline_images: true).to_svg)
    end
  end

  # Objects touch the star they orbit when they change, so the star's cache version covers them.
  # Advancing orbits moves bodies without touching them, so the system's elapsed days are part of the key.
  # The companion is the one drawn object that doesn't orbit the star.
  def orbit_map_cache_key(format, star, theme, linked)
    ['star_orbit_map', format, current_campaign.id, StarOrbitMap::VERSION, theme, linked,
     star.cache_key_with_version, star.companion&.cache_key_with_version, star.system_elapsed_days]
  end
end
