# GET /c/:campaign_slug/api/stars/:id/orbit_map(.svg|.webp)?theme=&download=
#
# The :id is a Star's id (unlike Api::StarsController, which is keyed by star system).
# Needs a session cookie or the campaign's Bearer API token. A token caller gets an SVG with no
# links in it, since it is for use outside the app; a logged-in user's SVG links to the app.
class Api::StarOrbitMapsController < Api::BaseController
  include OrbitMapRendering

  before_action :authenticate_user_or_token!

  def show
    star = Star.find_by(id: params[:id])
    return render json: { error: 'star not found' }, status: :not_found unless star

    theme = OrbitMapTheme.key_for(params[:theme])
    disposition = params[:download].present? ? 'attachment' : 'inline'

    case request.format.symbol
    when :svg
      send_data cached_orbit_map_svg(star, theme: theme, linked: !authenticated_by_token?),
                type: 'image/svg+xml', disposition: disposition, filename: star.orbit_map_download_filename('svg')
    when :webp
      send_data cached_orbit_map_webp(star, theme: theme),
                type: 'image/webp', disposition: disposition, filename: star.orbit_map_download_filename
    else
      render json: { error: 'format must be svg or webp' }, status: :not_acceptable
    end
  end
end
