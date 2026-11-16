# Public, campaign-independent API documentation served at /api.
#
# The docs list the campaign's API as the first server, so requests tried from
# the page go to the right campaign without the reader editing anything. The campaign is, in order: `?campaign=my-slug`, else the
# one the signed-in user referees, else a placeholder.
class ApiDocsController < ApplicationController
  optional_authentication only: %i[show spec]

  SLUG_FORMAT = /\A[\w-]+\z/

  def show
    @noindex = false
    @campaign_slug = campaign_slug_param || Current.user&.campaigns&.order(:id)&.first&.slug
    render layout: false
  end

  def spec
    slug = campaign_slug_param
    return send_data OpenapiBundle.yaml, type: 'application/yaml', disposition: 'inline' unless slug

    # A concrete server URL, not just a default for the `{campaign_slug}`
    # variable: Scalar's request client sends the template unfilled.
    document = OpenapiBundle.document
    document['servers'].unshift('url' => "/c/#{slug}/api", 'description' => "Campaign: #{slug}")
    send_data document.to_yaml, type: 'application/yaml', disposition: 'inline'
  end

  private

  def campaign_slug_param
    slug = params[:campaign].to_s
    slug if slug.match?(SLUG_FORMAT)
  end
end
