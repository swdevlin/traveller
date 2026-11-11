# frozen_string_literal: true

# Generates the map for a single planet, planetoid or moon. Enqueued in bulk from a star system,
# so it re-checks eligibility at run time and never replaces an existing map.
class GeneratePlanetMapJob < ApplicationJob
  queue_as :default

  retry_on MapService::Error, wait: :polynomially_longer, attempts: 3

  # Random priority within this range, so one user's batch interleaves with other users' jobs.
  PRIORITY_RANGE = (100..200)

  # base_url is the requesting site's origin; the map payload embeds absolute URLs built from it.
  def self.enqueue(stellar_object, base_url:)
    set(priority: rand(PRIORITY_RANGE)).perform_later(stellar_object.id, base_url)
  end

  def perform(stellar_object_id, base_url)
    stellar_object = StellarObject.find_by(id: stellar_object_id)
    return unless stellar_object.try(:map_supported?)
    return if stellar_object.planet_map.present?

    campaign = Campaign.find_by(schema_name: Apartment::Tenant.current)
    # The job is only ever queued by the campaign's referee, so render with referee visibility.
    Current.campaign = campaign
    Current.api_token_authenticated = true

    payload = JSON.parse(renderer(base_url, campaign).render(partial: 'stellar_objects/stellar_object', formats: [:json],
                                                             locals: { stellar_object: stellar_object }))
    rendered = MapService.new(campaign_id: campaign&.id).render(payload)
    stellar_object.store_map(rendered.svg)
  end

  private

  # Renders as if requested at /c/<slug>/..., so URL helpers produce campaign-scoped absolute URLs.
  def renderer(base_url, campaign)
    uri = URI.parse(base_url)
    ApplicationController.renderer.new(
      http_host: [uri.host, (uri.port unless uri.port == uri.default_port)].compact.join(':'),
      https: uri.scheme == 'https',
      'action_dispatch.request.path_parameters' => { campaign_slug: campaign&.slug }.compact
    )
  end
end
