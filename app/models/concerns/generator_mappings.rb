# frozen_string_literal: true

module GeneratorMappings
  extend ActiveSupport::Concern

  included do
    keys =
      if self.class.const_defined?(:API_DATA_MAP)
        self.class::API_DATA_MAP.keys
      else
        []
      end

    store_accessor :data, *keys
  end

  class_methods do
    def mapped_data_from_generator(payload)
      payload = payload.stringify_keys
      api_data_map.transform_values { |api_key| payload[api_key] }
    end

    def api_data_map
      base = { build_log: 'buildLog' }
      base.merge(const_get(:API_DATA_MAP))
    rescue NameError
      base
    end

    def allowed_data_keys
      const_get(:API_DATA_MAP).keys
    end
  end

  def assign_data_from_generator(payload, merge: true)
    mapped = self.class.mapped_data_from_generator(payload)

    self.data ||= {}
    self.data = merge ? self.data.merge(mapped) : mapped
    self
  end
end
