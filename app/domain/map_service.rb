# frozen_string_literal: true

require 'net/http'

# Client for the planetmap service, which turns a planet's JSON into an SVG map.
class MapService
  PLANET_SEED = 12_345

  Rendered = Struct.new(:svg, :seed, keyword_init: true)

  # Raised for any non-200 response. api_message is the service's JSON "error" message, safe to
  # show users; it is nil for anything else (e.g. an nginx HTML 502), which only goes in the log.
  class Error < StandardError
    attr_reader :status, :api_message

    def initialize(status, api_message, detail = nil)
      @status = status
      @api_message = api_message
      super("planetmap returned HTTP #{status}: #{api_message || detail}")
    end
  end

  def initialize(campaign_id: nil)
    @campaign_id = campaign_id
  end

  # POSTs the planet JSON untouched (a single top-level object, never wrapped) and returns
  # the SVG together with the seed the service used. Pass no seed for a random one.
  def render(planet_json, seed: nil)
    uri = URI.join(base_url.end_with?('/') ? base_url : "#{base_url}/", 'map')

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 30

    headers = { 'Content-Type' => 'application/json', 'Accept' => 'image/svg+xml' }
    headers['X-Planet-Seed'] = seed.to_s unless seed.nil?
    headers['x-tenant-id'] = @campaign_id.to_s if @campaign_id.present?

    response = http.post(uri.request_uri, planet_json.to_json, headers)
    Rails.logger.info "MapService POST #{uri} planet=#{planet_json['id']} seed=#{seed.inspect} " \
                      "status=#{response.code} svg_bytes=#{response.body.to_s.bytesize}"

    raise Error.new(response.code.to_i, error_message(response.body), response.body.to_s.truncate(300)) unless response.code == '200'

    Rendered.new(svg: response.body, seed: response['X-Planet-Seed'])
  end

  private

  def error_message(body)
    parsed = JSON.parse(body)
    parsed['error'].presence if parsed.is_a?(Hash)
  rescue JSON::ParserError
    nil
  end

  def base_url
    Rails.application.config.x.map_service
  end
end
