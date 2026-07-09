# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class ImportTravellerMapAllegiancesJob < ApplicationJob
  queue_as :default

  def perform
    uri = URI('https://travellermap.com/t5ss/allegiances')

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      open_timeout: 50,
      read_timeout: 600
    ) do |http|
      http.get(uri.request_uri, { 'Accept' => 'application/json' })
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}"
      return
    end

    allegiances = JSON.parse(response.body)
    Allegiance.upsert_all(
      allegiances.map { |a| { code: a['Code'], name: a['Name'], legacy_code: a['LegacyCode'] } },
      unique_by: :code
    )

    ActionCable.server.broadcast(
      'ui_updates',
      { event: 'allegiances_updated', at: Time.current.iso8601 }
    )

  rescue Errno::ECONNRESET => e
    Rails.logger.warn "#{uri} network error: #{e.class} #{e.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "#{uri} timeout: #{e.class} #{e.message}"
  rescue JSON::ParserError => e
    Rails.logger.error "#{uri} JSON Error: #{e.message} - Body: #{response&.body}"
  end
end
