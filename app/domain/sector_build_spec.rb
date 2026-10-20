# Builds the default subsector build configuration (YAML) for a new sector from
# the choices offered on the new sector form.
class SectorBuildSpec
  DENSITY_OPTIONS = [
    ['Dense (60%)', 'DENSE'],
    ['Standard (50%)', 'STANDARD'],
    ['Moderate (40%)', 'MODERATE'],
    ['Low (30%)', 'LOW'],
    ['Sparse (20%)', 'SPARSE'],
    ['Minimal (10%)', 'MINIMAL'],
    ['Rift (3%)', 'RIFT'],
    ['Rift fade (2%)', 'RIFT_FADE'],
    ['Deep rift (1%)', 'DEEP_RIFT'],
    ['Empty (0%)', 'EMPTY']
  ].freeze

  DEFAULT_DENSITY = 'STANDARD'.freeze
  DEFAULT_MAX_TECH_LEVEL = 15
  MAX_TECH_LEVEL_RANGE = (0..33).freeze
  KNOWN_SURVEY_INDEX = 10
  UNKNOWN_SURVEY_INDEX = 3

  def self.to_yaml(density:, known:, settled:, max_tech_level: DEFAULT_MAX_TECH_LEVEL)
    density = DEFAULT_DENSITY unless DENSITY_OPTIONS.any? { |_, value| value == density }
    max_tech_level = normalise_max_tech_level(max_tech_level)

    spec = {
      'type' => density,
      'defaultSI' => known ? KNOWN_SURVEY_INDEX : UNKNOWN_SURVEY_INDEX,
      'maxTechLevel' => max_tech_level
    }
    spec['populated'] = { 'type' => 'full', 'minTechLevel' => 0, 'maxTechLevel' => max_tech_level } if settled

    spec.to_yaml.delete_prefix("---\n")
  end

  def self.normalise_max_tech_level(value)
    level = Integer(value.to_s, 10, exception: false)
    level && MAX_TECH_LEVEL_RANGE.cover?(level) ? level : DEFAULT_MAX_TECH_LEVEL
  end
end
