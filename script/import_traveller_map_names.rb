# frozen_string_literal: true

require 'csv'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'set'
require 'fileutils'
require 'optparse'

class TravellerMapNameExporter
  BASE_URL = 'https://travellermap.com/data'
  SECTOR_FETCH_DELAY_SECONDS = 3

  def initialize(
    output_path:,
    official_only: true,
    allegiance_matches: [],
    max_sectors: nil
  )
    @output_path = Rails.root.join(output_path)
    @official_only = official_only
    @allegiance_matches = allegiance_matches
    @max_sectors = max_sectors
    @entries = []
    @seen = Set.new
  end

  def export!
    selected_sectors = sectors
    selected_sectors = selected_sectors.first(@max_sectors) if @max_sectors

    selected_sectors.each do |sector|
      sector_name = nil

      begin
        sector_name = sector_name_for(sector)
        next if blank?(sector_name)

        puts "Importing #{sector_name}..."

        sector_text = fetch(sector_uri(sector_name))
        parsed_sector = parse_sector_file(sector_text)

        parsed_sector[:worlds].each do |world|
          next unless include_world?(world)

          add_entry(
            category: 'world',
            name: world[:name]
          )
        end
      rescue StandardError => e
        warn "Failed #{sector_name || 'unknown sector'}: #{e.class} - #{e.message}"
      ensure
        sleep SECTOR_FETCH_DELAY_SECONDS
      end
    end

    write_output!

    puts "Wrote #{@entries.size} names to #{@output_path}"
  end

  private

  def sectors
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(requireData: 1)

    data = JSON.parse(fetch(uri))
    sector_list = data.fetch('Sectors')

    return sector_list unless @official_only

    sector_list.select do |sector|
      sector['Tags'].to_s.split.include?('Official')
    end
  end

  def parse_sector_file(text)
    parsed = {
      name: nil,
      abbreviation: nil,
      milieu: nil,
      subsectors: {},
      allegiances: {},
      worlds: []
    }

    lines = text.lines.map(&:rstrip)

    lines.each do |line|
      case line
      when /\A# Name:\s*(.+)\z/
        parsed[:name] = clean_name(Regexp.last_match(1))
      when /\A# Abbreviation:\s*(.+)\z/
        parsed[:abbreviation] = clean_name(Regexp.last_match(1))
      when /\A# Milieu:\s*(.+)\z/
        parsed[:milieu] = clean_name(Regexp.last_match(1))
      when /\A# Subsector ([A-P]):\s*(.*)\z/
        index = Regexp.last_match(1)
        name = clean_name(Regexp.last_match(2))
        parsed[:subsectors][index] = name unless blank?(name)
      when /\A# Alleg:\s*(\S+):\s*"?(.+?)"?\s*\z/
        code = Regexp.last_match(1)
        name = clean_name(Regexp.last_match(2))
        parsed[:allegiances][code] = name
      end
    end

    header_index = lines.index do |line|
      line.start_with?('Hex') && line.include?('Name') && line.include?('UWP')
    end

    return parsed unless header_index

    data_lines = lines[(header_index + 2)..] || []

    data_lines.each do |line|
      next if blank?(line)
      next if line.start_with?('#')

      world = parse_world_line(line)
      parsed[:worlds] << world if world
    end

    parsed
  end

  def parse_world_line(line)
    hex = line[0, 4]&.strip
    name = line[5, 20]&.strip

    return nil unless hex&.match?(/\A\d{4}\z/)
    return nil if blank?(name)

    tokens = line.split
    allegiance_code = parse_allegiance_code(tokens)

    {
      hex: hex,
      name: clean_name(name),
      allegiance_code: allegiance_code
    }
  end

  def parse_allegiance_code(tokens)
    return nil if tokens.size < 2

    pbg_index = tokens.index do |token|
      token.match?(/\A[0-9?][0-9?][0-9?]\z/)
    end

    return tokens[pbg_index + 2] if pbg_index && tokens[pbg_index + 2]

    nil
  end

  def include_world?(world)
    return true if @allegiance_matches.empty?

    allegiance_code = world[:allegiance_code].to_s

    @allegiance_matches.any? do |match|
      allegiance_code.include?(match)
    end
  end

  def add_entry(category:, name:)
    cleaned_name = clean_name(name)
    return if blank?(cleaned_name)

    normalised_name = normalise(cleaned_name)
    key = [category, normalised_name]

    return if @seen.include?(key)

    @seen << key

    @entries << {
      category: category,
      name: cleaned_name
    }
  end

  def write_output!
    FileUtils.mkdir_p(File.dirname(@output_path))

    CSV.open(@output_path, 'w:UTF-8', col_sep: "\t") do |csv|
      @entries.each do |entry|
        csv << [
          entry[:name]
        ]
      end
    end
  end

  def sector_name_for(sector)
    Array(sector['Names']).first&.fetch('Text', nil) ||
      sector['Name'] ||
      sector['Abbreviation']
  end

  def sector_uri(sector_name)
    URI("#{BASE_URL}/#{path_escape(sector_name)}")
  end

  def path_escape(value)
    CGI.escape(value).gsub('+', '%20')
  end

  def fetch(uri)
    response = Net::HTTP.get_response(uri)

    unless response.is_a?(Net::HTTPSuccess)
      raise "HTTP #{response.code} for #{uri}"
    end

    response.body.force_encoding(Encoding::UTF_8)
  end

  def clean_name(name)
    name
      .to_s
      .dup
      .force_encoding(Encoding::UTF_8)
      .scrub
      .unicode_normalize(:nfkc)
      .strip
      .gsub(/[’‘]/, "'")
      .gsub(/[–—]/, '-')
      .squeeze(' ')
  end

  def normalise(name)
    clean_name(name).downcase
  end

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end

options = {
  output_path: 'tmp/traveller_map_names.tsv',
  official_only: true,
  allegiance_matches: [],
  max_sectors: nil
}

parser = OptionParser.new do |opts|
  opts.banner = <<~TEXT
    Usage:
      bin/rails runner script/import_traveller_map_names.rb -- [options]

    Examples:
      bin/rails runner script/import_traveller_map_names.rb -- --max-sectors 5
      bin/rails runner script/import_traveller_map_names.rb -- --allegiance-matches Im,NaHu --output tmp/imperial_and_nahu_names.tsv
      bin/rails runner script/import_traveller_map_names.rb -- --all-sectors --output tmp/all_names.tsv
  TEXT

  opts.on('--output PATH', 'Output TSV path. Default: tmp/traveller_map_names.tsv') do |value|
    options[:output_path] = value
  end

  opts.on(
    '--allegiance-matches LIST',
    'Only include worlds whose allegiance code includes any comma-separated value, e.g. Im,NaHu'
  ) do |value|
    options[:allegiance_matches] = value
                                     .to_s
                                     .split(',')
                                     .map(&:strip)
                                     .reject(&:empty?)
  end

  opts.on('--max-sectors COUNT', Integer, 'Only fetch the first COUNT sectors') do |value|
    options[:max_sectors] = value
  end

  opts.on('--all-sectors', 'Include non-Official sectors too') do
    options[:official_only] = false
  end

  opts.on('-h', '--help', 'Show help') do
    puts opts
    exit
  end
end

parser.parse!(ARGV)

TravellerMapNameExporter.new(**options).export!
