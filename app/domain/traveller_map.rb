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

    parse_tab_delimited(body)
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

  def systems_to_build_plan(systems)
    {
      'type' => 'STANDARD',
      'systems' => systems.map { |sys| build_system_definition(sys) }
    }.to_yaml
  end

  def ensure_allegiances(systems)
    systems.each do |sys|
      code = sys['Allegiance'].presence
      next unless code

      Allegiance.find_or_create_by!(code: code) do |a|
        a.name = code
      end
    end
  end

  private

  def build_system_definition(sys)
    hex = sys['Hex']
    x = ((hex[0, 2].to_i - 1) % 8) + 1
    y = ((hex[2, 2].to_i - 1) % 10) + 1

    entry = { 'x' => x, 'y' => y }
    entry['name'] = sys['Name'] if sys['Name'].present?

    pbg = sys['PBG']
    if pbg.blank? || pbg == '???'
      entry['surveyIndex'] = 3
    else
      entry['surveyIndex'] = 12
      entry['counts'] = {
        'mainWorld' => { 'uwp' => sys['UWP'], 'orbit' => 'hzco', 'name' => sys['Name'] },
        'terrestrialPlanets' => pbg[0].to_i,
        'planetoidBelts' => pbg[1].to_i,
        'gasGiants' => pbg[2].to_i
      }
      stars = parse_stars(sys['Stars'])
      entry['primary'] = stars.first
      case stars.length
      when 2
        entry['primary']['near'] = stars[1]
      when 3
        entry['primary']['near'] = stars[1]
        entry['primary']['far'] = stars[2]
      when 4..9
        entry['primary']['close'] = stars[1]
        entry['primary']['near'] = stars[2]
        entry['primary']['far'] = stars[3]
      end
    end

    entry['bases'] = sys['Bases'].present? ? sys['Bases'].chars : []
    entry['allegiance'] = sys['Allegiance'].presence

    entry.compact
  end

  def parse_stars(stars)
    return [] if stars.blank?

    stars.split(/\s+/).each_slice(2).filter_map do |type, klass|
      next if type.nil? || klass.nil?
      { 'type' => type, 'class' => klass }
    end
  end

  def parse_tab_delimited(body)
    lines = body.lines.map(&:chomp)
    return [] if lines.empty?

    headers = lines.first.split("\t")
    lines[1..].map do |line|
      values = line.split("\t")
      headers.each_with_index.with_object({}) do |(header, i), hash|
        hash[header] = values[i]
      end
    end
  end
end
