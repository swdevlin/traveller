# frozen_string_literal: true

require 'dry-schema'

ORBIT_TYPES = %w[habitable warm cold].freeze

UWP_CODE = /\A[0-9A-Z][0-9A-F]{6}-[0-9A-F]\z/i
UWP_LABELS = [
  'terrestrial',
  'Small Gas Giant',
  'Large Gas Giant',
  'empty'
].freeze

CoordinateSchema = Dry::Schema.Params do
  required(:x).filled(:integer, gteq?: 1, lteq?: 8)
  required(:y).filled(:integer, gteq?: 1, lteq?: 10)
end

BaseStarSchema = Dry::Schema.Params do
  CLASS_TYPES = %w[Ia Ib II III IV V VI giant].freeze
  SPECTRAL_TYPES = /\A[OBAFGKM][0-9]\z/

  required(:type).filled(:string, format?: SPECTRAL_TYPES)
  required(:class).filled(:string, included_in?: CLASS_TYPES)

  optional(:bodies).array(:hash) do
    required(:uwp).value(:string) { included_in?(UWP_LABELS) | format?(UWP_CODE) }
    optional(:orbit).filled(:string, included_in?: ORBIT_TYPES)
    optional(:mainWorld).filled(:bool)
  end
end

StarSchema = BaseStarSchema.merge(
  Dry::Schema.Params do
    optional(:companion).hash(BaseStarSchema)
    optional(:close).hash(BaseStarSchema)
    optional(:near).hash(BaseStarSchema)
    optional(:far).hash(BaseStarSchema)
  end
)

PopulatedSchema = Dry::Schema.Params do
  POPULATED_TYPES = %w[full hard-horizontal hard-vertical split-horizontal split-vertical].freeze

  required(:type).filled(:string, included_in?: POPULATED_TYPES)
  required(:allegiance).filled(:string)
  optional(:minTechLevel).filled(:integer, gteq?: 0, lteq?: 100)
  optional(:maxTechLevel).filled(:integer, gteq?: 0, lteq?: 100)
  optional(:minPopulationCode).filled(:integer, gteq?: 0, lteq?: 16)
  optional(:maxPopulationCode).filled(:integer, gteq?: 0, lteq?: 16)
end

SystemSchema = Dry::Schema.Params do
  required(:x).filled(:integer, gteq?: 1, lteq?: 8)
  required(:y).filled(:integer, gteq?: 1, lteq?: 10)
  optional(:name).filled(:string)
  optional(:populated).hash(PopulatedSchema)
  optional(:primary).hash(StarSchema)
  optional(:surveyIndex).filled(:integer, gteq?: 0, lteq?: 12)
  optional(:know).filled(:bool)
  optional(:bases).array(:string).each(:filled?)
end

BuildConfigSchema = Dry::Schema.Params do
  config.validate_keys = true

  VALID_TYPES = %w[DENSE STANDARD MODERATE LOW SPARSE MINIMAL RIFT RIFT_FADE DEEP_RIFT EMPTY].freeze

  optional(:unusualChance).filled(:integer, gteq?: 0, lteq?: 100)
  optional(:defaultSI).filled(:integer, gteq?: 0, lteq?: 12)
  required(:type).filled(:string, included_in?: VALID_TYPES)

  optional(:exclude).value(:array).each { hash(CoordinateSchema) }
  optional(:required).value(:array).each { hash(SystemSchema) }
  optional(:systems).value(:array).each { hash(SystemSchema) }

  optional(:populated).hash(PopulatedSchema)
end
