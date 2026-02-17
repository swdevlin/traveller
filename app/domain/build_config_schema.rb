# frozen_string_literal: true

require 'dry-schema'

ORBIT_TYPES = %w[hzco inner outer habitable warm cold].freeze
BODY_ORBIT_TYPES = %w[inner warm hzco cold outer habitable].freeze

UWP_CODE = /\A[0-9A-Z][0-9A-F]{6}-[0-9A-H]\z/i
UWP_LABELS = [
  'terrestrial',
  'small gas giant',
  'gas giant',
  'planetoid belt',
  'large gas giant',
  'super earth',
  'empty'
].freeze

CoordinateSchema = Dry::Schema.Params do
  required(:x).filled(:integer, gteq?: 1, lteq?: 8)
  required(:y).filled(:integer, gteq?: 1, lteq?: 10)
end

CountsSchema = Dry::Schema.Params do
  optional(:density).filled(:integer, gteq?: 0, lteq?: 30)
  optional(:terrestrialPlanets).filled(:integer, gteq?: 0, lteq?: 20)
  optional(:planetoidBelts).filled(:integer, gteq?: 0, lteq?: 20)
  optional(:gasGiants).filled(:integer, gteq?: 0, lteq?: 20)
  optional(:mainWorld).filled(:hash) do
    required(:uwp).value(:string) { included_in?(UWP_LABELS) | format?(UWP_CODE) }
    optional(:orbit).maybe do
      (int? & gteq?(1)) | (str? & included_in?(ORBIT_TYPES))
    end
    optional(:name).filled(:string)
  end
end

BaseStarSchema = Dry::Schema.Params do
  CLASS_TYPES = %w[Ia Ib II III IV V VI giant].freeze
  SPECIAL_TYPES = Star::SPECIAL_SPECTRAL_TYPES.keys.join('|')
  SPECTRAL_TYPES = /\A(?:[OBAFGKM][0-9]|#{SPECIAL_TYPES})\z/

  required(:type).filled(:string, format?: SPECTRAL_TYPES)

  optional(:class).filled(:string, included_in?: CLASS_TYPES)

  optional(:bodies).array(:hash) do
    required(:uwp).value(:string) { included_in?(UWP_LABELS) | format?(UWP_CODE) }
    optional(:orbit).filled(:string, included_in?: BODY_ORBIT_TYPES)
    optional(:name).filled(:string)
    optional(:mainWorld).filled(:bool)
  end
end

NestedStarSchema = BaseStarSchema.merge(
  Dry::Schema.Params do
    optional(:companion).hash(BaseStarSchema)
    optional(:close).hash(BaseStarSchema)
    optional(:near).hash(BaseStarSchema)
    optional(:far).hash(BaseStarSchema)
  end
)

StarSchema = BaseStarSchema.merge(
  Dry::Schema.Params do
    optional(:companion).hash(NestedStarSchema)
    optional(:close).hash(NestedStarSchema)
    optional(:near).hash(NestedStarSchema)
    optional(:far).hash(NestedStarSchema)
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
  optional(:primary).hash(StarSchema)
  optional(:surveyIndex).filled(:integer, gteq?: 0, lteq?: 12)
  optional(:bases).array(:string).each(:filled?)
  optional(:known).filled(:bool)
  optional(:allegiance).filled(:string)
  optional(:counts).hash(CountsSchema)
end

SingleSystemSchema = Dry::Schema.Params do
  optional(:name).filled(:string)
  optional(:populated).hash(PopulatedSchema)
  optional(:primary).hash(StarSchema)
  optional(:surveyIndex).filled(:integer, gteq?: 0, lteq?: 12)
  optional(:bases).array(:string).each(:filled?)
  optional(:known).filled(:bool)
  optional(:allegiance).filled(:string)
  optional(:counts).hash(CountsSchema)
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
