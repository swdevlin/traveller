# frozen_string_literal: true

module NormalizesPlanetaryData
  extend ActiveSupport::Concern

  BOOLEAN_TYPE = ActiveModel::Type::Boolean.new

  FLOAT_FIELDS = %i[
    period
    rotation
    density
    gravity
    temperature
    axial_tilt
    albedo
    greenhouse
  ].freeze

  INTEGER_FIELDS = %i[
    habitability_rating
    biomass_rating
    biocomplexity_rating
    biodiversity_rating
    resource_rating
  ].freeze

  BOOLEAN_FIELDS = %i[
    retrograde
    native_sophont
    extinct_sophont
  ].freeze

  included do
    after_initialize :normalize_data_types
    before_validation :normalize_data_types
  end

  def normalize_data_types
    cast_fields(FLOAT_FIELDS, :to_f)
    cast_fields(INTEGER_FIELDS, :to_i)
    cast_boolean_fields(BOOLEAN_FIELDS)
  end

  private

  def cast_fields(fields, method_name)
    fields.each do |field|
      public_send(:"#{field}=", public_send(field).presence&.public_send(method_name))
    end
  end

  def cast_boolean_fields(fields)
    fields.each do |field|
      value = BOOLEAN_TYPE.cast(public_send(field))
      public_send(:"#{field}=", value.nil? ? false : value)
    end
  end
end
