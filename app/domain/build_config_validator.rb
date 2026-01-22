# frozen_string_literal: true

require_relative 'build_config_schema'

class BuildConfigValidator
  attr_reader :errors, :config

  def initialize(yaml_string)
    @yaml_string = yaml_string
    @errors = []
    @config = nil
  end

  def valid?
    @errors = []
    parse_yaml && validate_schema && validate_business_rules
    @errors.empty?
  end

  private

  def parse_yaml
    @config = YAML.safe_load(
      @yaml_string,
      permitted_classes: [],
      permitted_symbols: [],
      aliases: false
    )

    unless @config.is_a?(Hash)
      @errors << 'Build config must be a YAML hash/map'
      return false
    end

    # Normalize keys to strings and handle nil values in arrays
    @config = normalize_config(@config)
    true
  rescue Psych::SyntaxError => e
    @errors << "Invalid YAML syntax: #{e.message}"
    false
  rescue Psych::DisallowedClass => e
    @errors << "Disallowed YAML content: #{e.message}"
    false
  rescue => e
    @errors << "Failed to parse YAML: #{e.message}"
    false
  end

  def normalize_config(hash)
    hash.transform_keys(&:to_s).transform_values do |value|
      case value
      when Array
        # Remove nil entries from coordinate arrays
        value.compact
      else
        value
      end
    end.tap do |h|
      # Normalize chance to uppercase for case-insensitive matching
      h['type'] = h['type'].upcase if h['type'].is_a?(String)
    end
  end

  def validate_schema
    result = BuildConfigSchema.call(@config)

    unless result.success?
      result.errors.to_h.each do |field, messages|
        messages.each do |message|
          @errors << "#{field}: #{message}"
        end
      end
      return false
    end

    true
  end

  def validate_business_rules
    validate_systems_exclusivity
    validate_populated_allegiance
    validate_populated_tech_level
    validate_populated_population
    validate_primary_star
    @errors.empty?
  end

  def validate_populated_tech_level
    return if @config['populated'].nil?

    min = @config['populated']['minTechLevel']
    max = @config['populated']['maxTechLevel']
    return if min.nil? || max.nil?

    if min > max
      @errors << 'minTechLevel must be less than or equal to maxTechLevel'
    end
  end

  def validate_populated_population
    return if @config['populated'].nil?

    min = @config['populated']['minPopulationCode']
    max = @config['populated']['maxPopulationCode']
    return if min.nil? || max.nil?

    if min > max
      @errors << 'minPopulationCode must be less than or equal to maxPopulationCode'
    end
  end

  def validate_populated_allegiance
    return if @config['populated'].nil?

    allegiance = @config['populated']['allegiance']

    unless Allegiance.exists?(code: allegiance)
      @errors << "unknown allegiance '#{allegiance}'"
    end
  end

  def validate_systems_exclusivity
    systems = @config['systems']
    return unless systems.is_a?(Array) && systems.compact.any?

    exclude = @config['exclude']
    required = @config['required']

    exclude_present = exclude.is_a?(Array) && exclude.compact.any?
    required_present = required.is_a?(Array) && required.compact.any?

    if exclude_present || required_present
      @errors << 'When systems is specified, exclude and required must be empty'
    end
  end

  def validate_primary_star
    errors = []

    @config.fetch(:systems, []).each_with_index do |system, i|
      next unless system[:primary].is_a?(Hash)

      errors.concat(
        validate_star_tree(system[:primary], path: [:systems, i, :primary])
      )
    end

    errors
  end

  STAR_CHILD_KEYS = %i[companion close near far].freeze

  def validate_star_tree(star_hash, path:, max_depth: 10)
    return [] if star_hash.nil?
    return [[path, ['max recursion depth exceeded']]] if max_depth < 0

    errors = []

    result = StarSchema.call(star_hash)
    unless result.success?
      result.errors.to_h.each do |k, msgs|
        errors << [path + [k], Array(msgs)]
      end
    end

    STAR_CHILD_KEYS.each do |key|
      child = star_hash[key]
      next unless child.is_a?(Hash)

      errors.concat(
        validate_star_tree(child, path: path + [key], max_depth: max_depth - 1)
      )
    end

    errors
  end
end
