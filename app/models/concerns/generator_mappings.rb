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
      { 'build_log' => 'buildLog' }.merge(generator_api_data_map)
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
    return if moons.blank?

    now = Time.current
    records = Array(moons).map do |moon_data|
      moon = Moon.new
      moon.orbiting_id = id
      moon.star_system_id = star_system_id
      moon.parsec_id = parsec_id
      moon.assign_data_from_generator(moon_data)
      moon.size_code = moon.size_code.strip.upcase if moon.size_code.present?
      moon.data ||= {}
      moon.attributes.except('id').merge('created_at' => now, 'updated_at' => now)
    end

    Moon.insert_all!(records)
  rescue => e
    Rails.logger.error("assign_moons failed: #{e.message} | payloads: #{moons.inspect}")
    raise
  end

  def assign_data_from_generator(payload, merge: true)
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
