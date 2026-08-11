# frozen_string_literal: true

module GeneratorMappings
  extend ActiveSupport::Concern

  included do
    class_attribute :generator_api_data_map, default: {}
  end

  class_methods do
    def generator_data_map(map)
      self.generator_api_data_map = map.stringify_keys
      store_accessor :data, *generator_api_data_map.keys.map(&:to_sym)
    end

    def api_data_map
      generator_api_data_map
    end

    def mapped_data_from_generator(payload)
      payload = payload.stringify_keys
      api_data_map.transform_values { |api_key| payload[api_key] }.stringify_keys
    end

    def allowed_data_keys
      generator_api_data_map.keys
    end
  end

  def assign_moons(moons, campaign: nil)
    return [] if moons.blank?

    now = Time.current
    tidal_lock_targets = []
    moons_data = Array(moons)
    languages = []
    records = moons_data.map do |moon_data|
      moon = Moon.new
      moon.orbiting_id = id
      moon.star_system_id = star_system_id
      moon.parsec_id = parsec_id
      moon.assign_data_from_generator(moon_data)
      moon.size_code = moon.size_code.strip.upcase if moon.size_code.present?
      moon.data ||= {}
      tidal_lock_orbit_seq = moon_data['tidalLockTarget']
      if tidal_lock_orbit_seq.present?
        tidal_lock_targets << { orbit_sequence: moon.orbit_sequence, tidal_lock_orbit_seq: tidal_lock_orbit_seq }
      elsif moon_data['tidalLock'].present?
        moon.tidal_lock_target_id = id
      end
      has_cities = Array(moon_data['population']&.dig('majorCityPopulations')).present?
      languages << (campaign && has_cities && moon.effective_language(campaign))
      moon.attributes.except('id').merge('created_at' => now, 'updated_at' => now)
    end

    moon_ids = Moon.insert_all!(records, returning: %w[id]).rows.flatten

    city_records = moon_ids.each_with_index.flat_map do |moon_id, i|
      GeneratorMappings.city_records_for(moon_id, moons_data[i]['population'], languages[i], now)
    end
    City.insert_all!(city_records) if city_records.any?

    tidal_lock_targets
  rescue => e
    Rails.logger.error("assign_moons failed: #{e.message} | payloads: #{moons.inspect}")
    raise
  end

  def self.city_records_for(stellar_object_id, population_payload, language, now)
    populations = Array(population_payload&.dig('majorCityPopulations'))
    return [] if populations.blank?

    populations.map do |population|
      {
        'stellar_object_id' => stellar_object_id,
        'name' => language.present? ? WordGenerator.new(language: language.to_sym).generate : nil,
        'population' => population,
        'created_at' => now,
        'updated_at' => now
      }
    end
  end

  def self.build_tech_level_from_generator(tl)
    if tl.is_a?(Hash)
      code = tl['code']
      {
        'code'              => code,
        'energy'            => tl['energy'].nil?            ? code : tl['energy'],
        'electronics'       => tl['electronics'].nil?       ? code : tl['electronics'],
        'manufacturing'     => tl['manufacturing'].nil?     ? code : tl['manufacturing'],
        'medical'           => tl['medical'].nil?           ? code : tl['medical'],
        'environmental'     => tl['environmental'].nil?     ? code : tl['environmental'],
        'land'              => tl['landTransport'].nil?     ? code : tl['landTransport'],
        'sea'               => tl['waterTransport'].nil?    ? code : tl['waterTransport'],
        'air'               => tl['airTransport'].nil?      ? code : tl['airTransport'],
        'space'             => tl['spaceTransport'].nil?    ? code : tl['spaceTransport'],
        'personal_military' => tl['personalMilitary'].nil?  ? code : tl['personalMilitary'],
        'heavy_military'    => tl['heavyMilitary'].nil?     ? code : tl['heavyMilitary']
      }
    else
      { 'code' => tl }
    end
  end

  def self.build_government_from_generator(gov)
    if gov.is_a?(Hash)
      Governance.from_hash(gov)&.to_h || { 'code' => gov['code'] }
    else
      { 'code' => gov }
    end
  end

  def assign_data_from_generator(payload, merge: true)
    tech_level_payload = payload['techLevel']
    unless tech_level_payload.nil?
      self.data ||= {}
      self.data['tech_level'] = GeneratorMappings.build_tech_level_from_generator(tech_level_payload)
    end

    government_payload = payload['government'] || payload['governmentCode']
    unless government_payload.nil?
      self.data ||= {}
      self.data['government'] = GeneratorMappings.build_government_from_generator(government_payload)
    end

    total_urban_population_payload = payload['totalUrbanPopulation']
    unless total_urban_population_payload.nil?
      self.data ||= {}
      self.data['total_urban_population'] = total_urban_population_payload
    end

    mapped = self.class.mapped_data_from_generator(payload)

    self.diameter = payload['diameter']
    self.eccentricity = payload['eccentricity']
    self.inclination = payload['inclination']
    self.mass = payload['mass']
    self.build_log = payload['buildLog']
    self.orbit = payload['orbit']
    self.name = payload['name']
    raw_size = payload['size']
    unless raw_size.nil?
      self.size_code = raw_size.to_s.match?(/\A\d+\z/) ? HexDigit.hex_digit(raw_size.to_i) : raw_size.to_s
    end
    self.au = payload['au']
    self.survey_index = payload.fetch('surveyIndex', 0)
    self.effective_hzco_deviation = payload['effectiveHZCODeviation']
    self.orbit_sequence = payload.fetch('orbitSequence', nil)
    orbitPosition = payload.fetch('orbitPosition', {})
    self.orbit_x = orbitPosition.fetch('x', nil)
    self.orbit_y = orbitPosition.fetch('y', nil)

    allegiance = payload.fetch('allegiance', nil)
    unless allegiance.nil?
      self.allegiance = Allegiance.where(code: allegiance).sole
    end

    self.uwp = payload.fetch('uwp', nil)

    self.data ||= {}
    self.data = merge ? self.data.merge(mapped) : mapped
    self
  end
end
