# frozen_string_literal: true

require 'csv'
require 'json'
require 'net/http'
require 'uri'
require 'cgi'
require 'set'
require 'fileutils'

namespace :language do
  desc 'Fetch world names from TravellerMap and write language corpus files'
  task import: :environment do
    TravellerMapLanguageImporter.new.import!
  end
end

class TravellerMapLanguageImporter
  BASE_URL = 'https://travellermap.com/data'
  FULL_DELAY_SECONDS = 3
  SKIP_DELAY_SECONDS = 0.5

  TARGETS = [
    {
      name: 'Imperium',
      allegiance_matches: %w[Im NaHu],
      output_path: 'data/languages/imperium.txt'
    },
    {
      name: 'Gurvin (Hiver)',
      allegiance_matches: %w[Hv Hf],
      output_path: 'data/languages/gurvin.txt'
    }
  ].freeze

  def initialize
    @targets = TARGETS.map do |config|
      config.merge(
        output_path: Rails.root.join(config[:output_path]),
        entries: [],
        seen: Set.new
      )
    end
  end

  def import!
    sector_list = all_otu_sectors

    sector_list.each do |sector|
      sector_name = sector_name_for(sector)
      next if blank?(sector_name)

      begin
        sector_text = fetch(sector_uri(sector_name))
        sector_allegiances = parse_header_allegiances(sector_text)

        relevant = @targets.select do |target|
          sector_allegiances.any? do |code|
            target[:allegiance_matches].any? { |m| code.include?(m) }
          end
        end

        if relevant.any?
          puts "Importing #{sector_name} (#{relevant.map { |t| t[:name] }.join(', ')})..."
          parsed = parse_world_lines(sector_text)
          parsed.each { |world| distribute(world, relevant) }
          sleep FULL_DELAY_SECONDS
        else
          sleep SKIP_DELAY_SECONDS
        end
      rescue StandardError => e
        warn "Failed #{sector_name}: #{e.class} - #{e.message}"
        sleep SKIP_DELAY_SECONDS
      end
    end

    write_all!
  end

  private

  def all_otu_sectors
    uri = URI(BASE_URL)
    uri.query = URI.encode_www_form(requireData: 1)
    data = JSON.parse(fetch(uri))
    data.fetch('Sectors').select { |s| s['Tags'].to_s.include?('OTU') }
  end

  def parse_header_allegiances(text)
    text.lines.each_with_object([]) do |line, codes|
      line = line.rstrip
      if line =~ /\A# Alleg:\s*(\S+):/
        codes << Regexp.last_match(1)
      elsif line.start_with?('Hex') && line.include?('UWP')
        break codes
      end
    end
  end

  def parse_world_lines(text)
    worlds = []
    lines = text.lines.map(&:rstrip)

    header_index = lines.index { |l| l.start_with?('Hex') && l.include?('Name') && l.include?('UWP') }
    return worlds unless header_index

    (lines[(header_index + 2)..] || []).each do |line|
      next if blank?(line) || line.start_with?('#')

      world = parse_world_line(line)
      worlds << world if world
    end

    worlds
  end

  def parse_world_line(line)
    hex = line[0, 4]&.strip
    name = line[5, 20]&.strip

    return nil unless hex&.match?(/\A\d{4}\z/)
    return nil if blank?(name)

    tokens = line.split
    pbg_index = tokens.index { |t| t.match?(/\A[0-9?]{3}\z/) }
    allegiance_code = pbg_index ? tokens[pbg_index + 2] : nil

    { name: clean_name(name), allegiance_code: allegiance_code }
  end

  def distribute(world, targets)
    code = world[:allegiance_code].to_s
    name = world[:name]

    targets.each do |target|
      next unless target[:allegiance_matches].any? { |m| code.include?(m) }

      add_entry(target, name)
    end
  end

  def add_entry(target, name)
    cleaned = clean_name(name)
    return if blank?(cleaned)

    key = cleaned.downcase
    return if target[:seen].include?(key)

    target[:seen] << key
    target[:entries] << cleaned
  end

  def write_all!
    @targets.each do |target|
      FileUtils.mkdir_p(File.dirname(target[:output_path]))
      File.open(target[:output_path], 'w:UTF-8') do |f|
        target[:entries].each { |name| f.puts name }
      end
      puts "Wrote #{target[:entries].size} names to #{target[:output_path]}"
    end
  end

  def sector_name_for(sector)
    Array(sector['Names']).first&.fetch('Text', nil) ||
      sector['Name'] ||
      sector['Abbreviation']
  end

  def sector_uri(sector_name)
    URI("#{BASE_URL}/#{CGI.escape(sector_name).gsub('+', '%20')}")
  end

  def fetch(uri)
    response = Net::HTTP.get_response(uri)
    raise "HTTP #{response.code} for #{uri}" unless response.is_a?(Net::HTTPSuccess)

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
      .gsub(/['']/, "'")
      .gsub(/[–—]/, '-')
      .squeeze(' ')
  end

  def blank?(value)
    value.nil? || value.to_s.strip.empty?
  end
end
