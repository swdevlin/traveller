# frozen_string_literal: true

module GeneratorMappings
  extend ActiveSupport::Concern

  included do
    class_attribute :generator_api_data_map, default: {}
    store_accessor :data, :build_log
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

  def assign_data_from_generator(payload, merge: true)
    mapped = self.class.mapped_data_from_generator(payload)

    self.diameter = payload['diameter']
    self.eccentricity = payload['eccentricity']
    self.inclination = payload['inclination']
    self.mass = payload['mass']
    self.orbit = payload['orbit']
    self.orbit_x = payload['orbitX']
    self.orbit_y = payload['orbitY']
    self.survey_index = payload.fetch('surveyIndex', 0)
    self.effective_hzco_deviation = payload['effectiveHZCODeviation']
    self.orbit_sequence = payload.fetch('orbitSequence', nil)
    self.uwp = payload.fetch('uwp', nil)

    self.data ||= {}
    self.data = merge ? self.data.merge(mapped) : mapped
    self
  end
end
