require 'net/http'
require 'uri'
require 'json'
require 'yaml'

class GenerateSubsectorJob < ApplicationJob
  queue_as :default

  def perform(subsector_id, definition)
    subsector = Subsector.find(subsector_id)
    config =
      YAML.safe_load(
        definition,
        permitted_classes: [Date, Time], # add more if you truly need them
        aliases: false
      ) || {}

    config = config.deep_symbolize_keys if config.respond_to?(:deep_symbolize_keys)
    %i[exclude required systems].each do |key|
      value = config[key]

      next unless value.is_a?(Array)

      config.delete(key) if value.compact.empty?
    end

    SubsectorChannel.broadcast_to(subsector, { event: 'populating' })
    Subsector.transaction do
      subsector.clear
    end

    base = Rails.application.config.x.generator_service
    uri  = URI.join(base.end_with?('/') ? base : "#{base}/", 'subsector')

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 50
    http.read_timeout = 600
    campaign_id = Campaign.find_by(schema_name: Apartment::Tenant.current)&.id
    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'x-tenant-id' => campaign_id.to_s
    }

    response = http.post(uri.request_uri, config.to_json, headers)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}" and return
    end

    systems =
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "#{uri} JSON Error: #{e.message} - Body: #{response.body}" and return
      end

    importer = StarSystemImporter.new
    ul, = subsector.universal_coordinates

    systems.each do |s|
      parsec = Parsec.find_by(x: ul.x + s['x']-1, y: ul.y - (s['y'] - 1))
      importer.import!(parsec, s)
    end

    SubsectorChannel.broadcast_to(subsector, { event: 'finished' })
  end
end
