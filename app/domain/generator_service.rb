# frozen_string_literal: true

require 'net/http'

class GeneratorService
  Result = Struct.new(:value, :errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  def initialize(campaign_id: nil)
    @campaign_id = campaign_id
  end

  def generate_star_system(definition)
    call_service('star_system', definition)
  end

  def generate_subsector(definition)
    call_service('subsector', definition)
  end

  def assign_social_characteristics(payload)
    call_service('social_characteristics', payload)
  end

  def compute_orbit_mechanics(payload)
    call_service('orbit_mechanics', payload)
  end

  def generate_stellar_object(klass, params: {})
    get_service(klass.name.underscore, params)
  end

  def generate_from_uwp(uwp:, orbit:, star:)
    call_service('uwp', { uwp: uwp, orbit: orbit, star: star })
  end

  def lookup_star(stellar_type:, stellar_subtype: nil, stellar_class: nil)
    query = { stellarType: stellar_type }
    query[:subtype] = stellar_subtype if stellar_subtype.present?
    query[:stellarClass] = stellar_class if stellar_class.present?
    get_service('star', query)
  end

  private

  def base_url
    Rails.application.config.x.generator_service
  end

  def get_service(endpoint, query = {})
    uri = URI.join(base_url.end_with?('/') ? base_url : "#{base_url}/", endpoint)
    uri.query = URI.encode_www_form(query)

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 10

    headers = { 'Accept' => 'application/json' }
    headers['x-tenant-id'] = @campaign_id.to_s if @campaign_id.present?
    response = http.get(uri.request_uri, headers)

    if response.is_a?(Net::HTTPBadRequest)
      begin
        msg = JSON.parse(response.body)['message'].presence || 'Invalid star classification'
      rescue JSON::ParserError
        msg = 'Invalid star classification'
      end
      return Result.new(errors: [msg])
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}"
      return Result.new(errors: ['Cannot look up star at this time'])
    end

    begin
      Result.new(value: JSON.parse(response.body))
    rescue JSON::ParserError => e
      Rails.logger.error "#{uri} JSON Error: #{e.message} - Body: #{response.body}"
      Result.new(errors: ['Cannot look up star at this time'])
    end
  end

  def call_service(endpoint, data)
    uri = URI.join(base_url.end_with?('/') ? base_url : "#{base_url}/", endpoint)

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 50
    http.read_timeout = 50

    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
    headers['x-tenant-id'] = @campaign_id.to_s if @campaign_id.present?

    response = http.post(uri.request_uri, data.to_json, headers)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}"
      return Result.new(errors: ['Cannot create star system at this time'])
    end

    begin
      parsed = JSON.parse(response.body)
      Result.new(value: parsed)
    rescue JSON::ParserError => e
      Rails.logger.error "#{uri} JSON Error: #{e.message} - Body: #{response.body}"
      Result.new(errors: ['Cannot create star system at this time'])
    end
  end
end
