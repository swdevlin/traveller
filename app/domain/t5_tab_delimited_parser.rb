# frozen_string_literal: true

class T5TabDelimitedParser
  def self.parse(text)
    new(parse_rows(text))
  end

  def self.parse_rows(text)
    lines = text.to_s.lines.map(&:chomp)
    return [] if lines.empty?

    headers = lines.first.split("\t")
    lines[1..].map do |line|
      values = line.split("\t")
      headers.each_with_index.with_object({}) do |(header, i), hash|
        hash[header] = values[i]
      end
    end
  end
  private_class_method :parse_rows

  def initialize(systems)
    @systems = systems
  end

  attr_reader :systems

  def ensure_allegiances
    systems.each do |sys|
      code = sys['Allegiance'].presence
      next unless code

      Allegiance.find_or_create_by!(code: code) do |a|
        a.name = code
      end
    end
  end

  def ensure_travel_zones
    systems.each do |sys|
      code = sys['Zone'].presence
      next unless code

      TravelZone.find_or_create_by!(code: code) do |tz|
        tz.name   = code
        tz.colour = '#6b7280'
      end
    end
  end

  def build_plan(survey_index: nil)
    plan = { 'type' => 'STANDARD' }
    plan['surveyIndex'] = survey_index if survey_index
    plan['systems'] = systems.map { |sys| build_system_definition(sys) }
    plan.to_yaml
  end

  def build_plans_by_subsector(survey_index: nil)
    ensure_allegiances
    ensure_travel_zones
    systems.group_by { |sys| subsector_letter_for_hex(sys['Hex']) }
           .compact
           .transform_values { |subset| self.class.new(subset).build_plan(survey_index: survey_index) }
  end

  def subsector_letter_for_hex(hex)
    return nil if hex.blank?

    col = hex[0, 2].to_i
    row = hex[2, 2].to_i
    return nil if col < 1 || col > 32 || row < 1 || row > 40

    ('A'..'P').to_a[((row - 1) / 10) * 4 + ((col - 1) / 8)]
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
      belts = pbg[1].to_i
      gas_giants = pbg[2].to_i
      entry['counts'] = {
        'mainWorld' => { 'uwp' => sys['UWP'], 'orbit' => 'hzco', 'name' => sys['Name'] },
        'terrestrialPlanets' => terrestrial_planet_count(sys['W'], pbg, belts, gas_giants),
        'planetoidBelts' => belts,
        'gasGiants' => gas_giants
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
    entry['travelZone'] = sys['Zone'].presence

    entry.compact
  end

  def terrestrial_planet_count(worlds, pbg, belts, gas_giants)
    return pbg[0].to_i if worlds.blank?

    (worlds.to_i - gas_giants - belts - 1).clamp(0, 20)
  end

  def parse_stars(stars)
    return [] if stars.blank?

    stars.split(/\s+/).each_slice(2).filter_map do |type, klass|
      next if type.nil? || klass.nil?
      { 'type' => type, 'class' => klass }
    end
  end
end
