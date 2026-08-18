# frozen_string_literal: true

require 'cgi'
require 'net/http'
require 'uri'
require 'json'
require 'yaml'

class TravellerMap
  def initialize
    super
    @url = 'https://travellermap.com/api'
  end

  def find_sectors(name:)
    body = search(term: name)
    return [] if body.nil?

    data = JSON.parse(body)
    items = data.dig('Results', 'Items') || []

    # Get only Sector-type results and deduplicate by coordinates
    sectors_by_coords = {}
    items.each do |item|
      next unless item.key?('Sector')

      sector = item['Sector']
      next unless sector && sector['Name']

      sector['SectorY'] = -sector['SectorY'].to_i
      coords = [sector['SectorX'], sector['SectorY']]
      sectors_by_coords[coords] ||= sector
    end

    sectors_by_coords.values.sort_by { |s| s['Name'] }
  end

  def fetch_subsector_systems(sector_x, sector_y, subsector_letter)
    body = fetch("sec?sx=#{sector_x}&sy=#{-sector_y}&type=TabDelimited&subsector=#{subsector_letter}")
    return [] if body.nil?

    T5TabDelimitedParser.parse(body).systems
  end

  def fetch_sector_metadata(sector_x, sector_y)
    body = fetch("metadata?sx=#{sector_x}&sy=#{-sector_y}")
    return {} if body.nil?
    JSON.parse(body)
  end

  def fetch(path)
    uri = URI("#{@url}/#{path}")

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      open_timeout: 15,
      read_timeout: 60
    ) do |http|
      http.get(uri.request_uri)
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}"
      return nil
    end

    response.body
  end

  def search(term:)
    uri = URI("#{@url}/search?q=#{ERB::Util.url_encode(term)}")

    response = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      open_timeout: 15,
      read_timeout: 30
    ) do |http|
      http.get(uri.request_uri, { 'Accept' => 'application/json' })
    end

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}"
      return nil
    end

    response.body
  end
end
