# frozen_string_literal: true

# Serves the star system detail JSON without rendering it again when nothing it
# depends on has changed. See StarSystemDetailVersion for what that means.
#
# Two layers share one key:
#   * a conditional GET: the response carries an ETag, and a caller whose copy is
#     current gets a 304 with no body, so the system is neither loaded nor rendered;
#   * the rendered JSON kept in Rails.cache, so another caller, or the same one
#     with an empty browser cache, skips the load and the render too.
#
# The key includes the base URL because the JSON holds absolute URLs, and who is
# asking, through the version, because a referee sees more than a player.
module StarSystemDetailCaching
  extend ActiveSupport::Concern

  CACHE_LIFETIME = 1.week

  private

  # What the JSON shows depends on this, so each gets its own cached copy. Where the partials
  # test Current.referee_access? the token counts as a referee; where they test
  # Current.owns_campaign? (sophont referee notes) only the signed-in owner does.
  def star_system_detail_viewer
    return :owner if Current.owns_campaign?
    return :referee_token if Current.referee_access?

    :player
  end

  # `template` is a jbuilder template that reads @star_system, and @parsec if it needs it;
  # pass `parsec` if the response includes the parsec's own fields.
  def render_star_system_detail(star_system, template:, parsec: nil)
    version = StarSystemDetailVersion.new(star_system, viewer: star_system_detail_viewer, parsec: parsec).digest
    key = ['star_system_detail', template, version, request.base_url]
    return unless stale?(etag: key)

    json = Rails.cache.fetch(key, expires_in: CACHE_LIFETIME) do
      @star_system = StarSystemDetailLoader.new(StarSystem.where(id: star_system.id), referee: @is_referee).load
      render_to_string(template, formats: [:json])
    end
    render json: json
  end
end
