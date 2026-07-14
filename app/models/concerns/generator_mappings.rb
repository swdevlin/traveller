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

  def assign_moons(moons)
    return [] if moons.blank?

    now = Time.current
    tidal_lock_targets = []
    records = Array(moons).map do |moon_data|
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
      moon.attributes.except('id').merge('created_at' => now, 'updated_at' => now)
    end

    Moon.insert_all!(records)
    tidal_lock_targets
  rescue => e
    Rails.logger.error("assign_moons failed: #{e.message} | payloads: #{moons.inspect}")
    raise
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

  def assign_data_from_generator(payload, merge: true)
    tech_level_payload = payload['techLevel']
    unless tech_level_payload.nil?
      self.data ||= {}
      self.data['tech_level'] = GeneratorMappings.build_tech_level_from_generator(tech_level_payload)
    end

    government_code_payload = payload['governmentCode']
    unless government_code_payload.nil?
      self.data ||= {}
      self.data['government'] = { 'code' => government_code_payload }
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
