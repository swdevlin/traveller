# Serves a subway map (star system or single star) as svg or webp.
#
# Including controllers define:
#   subway_map_cache_prefix - e.g. 'system_map'
#   subway_map_record       - the record whose cache version keys the output
#   subway_map_layout       - the StarSystemMapLayout to draw, or nil for the whole system
module SubwayMapRendering
  extend ActiveSupport::Concern

  # Bump when the subway map templates change, to invalidate cached output.
  SUBWAY_MAP_TEMPLATE_VERSION = 1

  private

  def send_subway_map
    @show_map_links = owns_campaign?
    fresh_when etag: "#{current_campaign.id}/#{subway_map_record.cache_key_with_version}/#{map_cache_variant}",
               last_modified: subway_map_record.updated_at
    return if performed?

    respond_to do |format|
      format.svg  { send_data cached_svg,  type: 'image/svg+xml', disposition: 'inline' }
      format.html { send_data cached_svg,  type: 'image/svg+xml', disposition: 'inline' }
      format.webp { send_data cached_webp, type: 'image/webp',    disposition: 'inline' }
    end
  end

  def map_cache_variant
    owns_campaign? ? "auth_v#{SUBWAY_MAP_TEMPLATE_VERSION}" : "public_v#{SUBWAY_MAP_TEMPLATE_VERSION}"
  end

  def subway_map_cache_key(format)
    "#{subway_map_cache_prefix}_#{format}/#{current_campaign.id}/#{subway_map_record.cache_key_with_version}/#{map_cache_variant}"
  end

  def cached_svg
    Rails.cache.fetch(subway_map_cache_key(:svg)) do
      @layout = subway_map_layout
      render_to_string('star_systems/map', formats: [:svg], layout: false)
    end
  end

  def cached_webp
    Rails.cache.fetch(subway_map_cache_key(:webp)) do
      SvgRasteriser.webp(SvgRasteriser.embed_images(cached_svg))
    end
  end
end
