# frozen_string_literal: true

require_relative 'build_config_schema'

class BuildConfigValidator
  attr_reader :errors, :config

  def initialize(yaml_string)
    @yaml_string = yaml_string
    @errors = []
    @config = nil
  end

  def valid_for_star_system?
    @errors = []
    parse_yaml && validate_star_system_schema && validate_star_system_business_rules
    @errors.empty?
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
      @errors.concat(humanise_schema_errors(result.errors.to_h))
      return false
    end

    true
  end

  def validate_star_system_schema
    result = SingleSystemSchema.call(@config)

    unless result.success?
      @errors.concat(humanise_schema_errors(result.errors.to_h))
      return false
    end

    true
  end

  def humanise_schema_errors(errors_hash)
    out = []
    flatten_errors(errors_hash, [], out)
    out
  end

  # Recursively walks Dry::Schema error hashes and produces friendly strings.
  def flatten_errors(node, path, out)
    case node
    when Hash
      node.each do |k, v|
        flatten_errors(v, path + [k], out)
      end
    when Array
      node.each do |v|
        flatten_errors(v, path, out)
      end
    else
      # node is a message string
      out << format_error(path, node.to_s)
    end
  end

  def format_error(path, message)
    friendly_path = path.map { |p| humanise_path_part(p) }.join(' → ')
    "#{friendly_path}: #{humanise_message(message)}"
  end

  def humanise_path_part(part)
    case part
    when Integer
      # 1-based indexing for humans
      "##{part + 1}"
    else
      part
      # Title-case unknown keys a bit
      # part.to_s.gsub(/([a-z])([A-Z])/, '\1 \2').tr('_', ' ').capitalize
    end
  end

  def humanise_message(message)
    message
      .gsub('is in invalid format', 'has an invalid format')
      .gsub('must be one of:', 'must be one of:')
  end

  def validate_business_rules
    validate_systems_exclusivity
    validate_populated_allegiance
    validate_populated_tech_level
    validate_populated_population
    validate_bases

    systems = Array(config['systems']) + Array(config['required'])
    systems.each_with_index do |sys, idx|
      validate_allegiance(sys)
      validate_counts(sys['counts'], "systems[#{idx}].counts")
      primary = sys['primary']
      next unless primary.is_a?(Hash)

      validate_star_tree(primary, "systems[#{idx}].primary")
    end

    @errors.empty?
  end

  def validate_star_system_business_rules
    validate_populated_allegiance
    validate_populated_tech_level
    validate_populated_population
    validate_bases

    validate_allegiance(config)
    validate_counts(config['counts'], config['counts'])
    primary = config['primary']

    validate_star_tree(primary, config['primary'])

    @errors.empty?
  end

  STAR_LINK_KEYS = %w[companion close near far].freeze
  STAR_SCHEMA_CHILD_KEYS = STAR_LINK_KEYS.freeze

  def validate_star_tree(star, path, max_depth: 10)
    return if star.nil?
    return @errors << "#{path}: max recursion depth exceeded" if max_depth < 0
    return unless star.is_a?(Hash)

    # 1) Schema validation (note: StarSchema expects symbol keys unless it’s Params + string keys)
    # If your schema is Dry::Schema.Params, it will coerce string keys fine.
    result = StarSchema.call(star)
    unless result.success?
      result.errors.to_h.each do |k, msgs|
        Array(msgs).each { |msg| @errors << "#{path}.#{k}: #{msg}" }
      end
    end

    # 2) BD/class conditional
    type  = star['type']
    klass = star['class']

    unless Star::SPECIAL_SPECTRAL_TYPES.key?(type&.upcase)
      @errors << "#{path}.class is required unless type is one of #{Star::SPECIAL_SPECTRAL_TYPES.keys.join(', ')}" if klass.nil?
    end

    # 3) Validate body orbit uniqueness
    bodies = star['bodies']
    validate_body_orbits(bodies, path) if bodies.is_a?(Array)

    # 4) Recurse into nested stars
    STAR_SCHEMA_CHILD_KEYS.each do |key|
      child = star[key]
      validate_star_tree(child, "#{path}.#{key}", max_depth: max_depth - 1) if child.is_a?(Hash)
    end
  end

  def validate_body_orbits(bodies, path)
    orbits = bodies.select { |b| b.is_a?(Hash) && b['orbit'].present? }
    return if orbits.size <= 1

    @errors << "#{path}.bodies: only one body may specify an orbit label"
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

  def validate_allegiance(path)
    return if path['allegiance'].nil?

    allegiance = path['allegiance']

    unless Allegiance.exists?(code: allegiance)
      @errors << "unknown allegiance '#{allegiance}'"
    end
  end

  def validate_bases
    return if @config['bases'].nil?

    @config['bases'].each do |base|
      unless Facility.exists?(code: base)
        @errors << "unknown base '#{base}'"
      end
    end
  end

  def validate_counts(counts, path)
    return unless counts.is_a?(Hash)

    has_density = counts.key?('density')
    has_explicit = counts.key?('terrestrialPlanets') &&
                   counts.key?('planetoidBelts') &&
                   counts.key?('gasGiants')

    unless has_density || has_explicit
      @errors << "#{path}: must specify either density or all of terrestrialPlanets, planetoidBelts, and gasGiants"
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
end
