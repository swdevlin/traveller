# frozen_string_literal: true

require 'dry-schema'

CoordinateSchema = Dry::Schema.Params do
  required(:x).filled(:integer, gteq?: 1, lteq?: 8)
  required(:y).filled(:integer, gteq?: 1, lteq?: 10)
end

PopulatedSchema = Dry::Schema.Params do
  required(:allegiance).filled(:string)
end

BuildConfigSchema = Dry::Schema.Params do
  config.validate_keys = true

  VALID_CHANCES = %w[DENSE STANDARD MODERATE LOW SPARSE MINIMAL RIFT RIFT_FADE DEEP_RIFT EMPTY].freeze

  optional(:unusualChance).filled(:integer, gteq?: 0, lteq?: 100)
  optional(:defaultSI).filled(:integer, gteq?: 0, lteq?: 12)
  required(:chance).filled(:string, included_in?: VALID_CHANCES)
  optional(:exclude).value(:array).each { hash(CoordinateSchema) }
  optional(:required).value(:array).each { hash(CoordinateSchema) }
  optional(:systems).value(:array).each { hash(CoordinateSchema) }
  optional(:populated).hash(PopulatedSchema)
end
