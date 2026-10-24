# Serves a subway map (star system or single star) as svg or webp.
#
# Including controllers define:
#   subway_map_cache_prefix - e.g. 'system_map'
#   subway_map_record       - the record whose cache version keys the output
#   subway_map_layout       - the StarSystemMapLayout to draw, or nil for the whole system
module SubwayMapRendering
  extend ActiveSupport::Concern

  # Bump when the subway map templates change, to invalidate cached output.
  SUBWAY_MAP_TEMPLATE_VERSION = 4

  included do
    helper_method :map_moons_mode
    before_action :remember_map_moons, only: :show
  end

  private

  # ?moons=significant or ?moons=all adds each planet's moons to the map; anything else leaves them off
  # (?moons=1 is the earlier spelling of significant). The show pages fall back to the last choice made
  # in this session; map endpoints (including signed public links) depend on the parameter alone.
  def map_moons_mode
    case params.fetch(:moons) { (session[:map_moons] if action_name == 'show') }
    when 'significant', '1' then :significant
    when 'all' then :all
    end
  end

  def remember_map_moons
    session[:map_moons] = params[:moons].to_s if params.key?(:moons)
  end

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
    audience = owns_campaign? ? 'auth' : 'public'
    "#{audience}_v#{SUBWAY_MAP_TEMPLATE_VERSION}#{"_moons_#{map_moons_mode}" if map_moons_mode}"
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
