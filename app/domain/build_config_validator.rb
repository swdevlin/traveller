# frozen_string_literal: true

require_relative 'build_config_schema'

class BuildConfigValidator
  attr_reader :errors, :config

  def self.government_type_codes(raw)
    return nil if raw.blank?

    government_type_tokens(raw).filter_map { |t| HexDigit::HEX_DIGITS.index(t.strip.upcase) }
  end

  # Converts governmentTypes (and before/after governmentTypes) within a `populated` hash
  # from a comma list/raw array into an integer array, in place. Handles both symbol-keyed
  # (post deep_symbolize_keys) and string-keyed populated hashes.
  def self.convert_populated_government_types!(populated)
    return if populated.nil?

    gt_key = populated.key?(:governmentTypes) ? :governmentTypes : 'governmentTypes'
    region_keys = populated.key?(:before) || populated.key?(:after) ? %i[before after] : %w[before after]

    populated[gt_key] = government_type_codes(populated[gt_key]) if populated[gt_key]

    region_keys.each do |region_key|
      region = populated[region_key]
      next unless region.is_a?(Hash)

      region[gt_key] = government_type_codes(region[gt_key]) if region[gt_key]
    end
  end

  # YAML has no bareword string type: an unquoted, comma-separated, all-numeric list such as
  # `governmentTypes: 1,2,5` is parsed by Psych as the *integer* 125 (commas are stripped as a
  # legacy thousands separator), not the string "1,2,5" — the comma is gone by the time we see
  # it, so a multi-digit integer here can only mean the referee needs to quote the value.
  def self.government_type_tokens(raw)
    case raw
    when Array then raw.map(&:to_s)
    when Integer then raw.to_s.length == 1 ? [raw.to_s] : []
    else raw.to_s.split(',')
    end
  end

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
      normalize_populated_government_types(h['populated']) if h['populated'].is_a?(Hash)
    end
  end

  def normalize_populated_government_types(pop)
    pop['governmentTypes'] = normalize_government_types(pop['governmentTypes']) if pop.key?('governmentTypes')

    %w[before after].each do |region|
      next unless pop[region].is_a?(Hash)
      next unless pop[region].key?('governmentTypes')
      pop[region]['governmentTypes'] = normalize_government_types(pop[region]['governmentTypes'])
    end
  end

  def normalize_government_types(raw)
    if raw.is_a?(Integer) && raw.to_s.length > 1
      @errors << 'governmentTypes: quote comma-separated values, e.g. governmentTypes: "1,2,5" ' \
                  '(YAML reads an unquoted numeric list as a single number)'
      return []
    end

    self.class.government_type_tokens(raw).map(&:strip)
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
    validate_populated_law_level
    validate_populated_population
    validate_populated_demarcation
    validate_bases
    validate_languages
    validate_government_types

    systems = Array(config['systems']) + Array(config['required'])
    systems.each_with_index do |sys, idx|
      validate_allegiance(sys)
      validate_counts(sys['counts'], "systems[#{idx}].counts")
      validate_mainworld_uniqueness(sys, "systems[#{idx}]")

      (%w[primary] + STAR_LINK_KEYS).each do |key|
        star = sys[key]
        validate_star_tree(star, "systems[#{idx}].#{key}") if star.is_a?(Hash)
      end
    end

    @errors.empty?
  end

  def validate_star_system_business_rules
    validate_populated_allegiance
    validate_populated_tech_level
    validate_populated_law_level
    validate_populated_population
    validate_populated_demarcation
    validate_bases
    validate_languages
    validate_government_types

    validate_allegiance(config)
    validate_counts(config['counts'], config['counts'])
    validate_mainworld_uniqueness(config, nil)

    (%w[primary] + STAR_LINK_KEYS).each do |key|
      star = config[key]
      validate_star_tree(star, key) if star.is_a?(Hash)
    end

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

    no_class_required = Star::SPECIAL_SPECTRAL_TYPES.key?(type&.upcase) ||
                         Star::BROWN_DWARF_TYPES.include?(type&.upcase&.slice(0, 1))
    unless no_class_required
      @errors << "#{path}.class is required unless type is one of #{Star::SPECIAL_SPECTRAL_TYPES.keys.join(', ')} " \
                  "or a brown dwarf type (#{Star::BROWN_DWARF_TYPES.join(', ')})" if klass.nil?
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

  def validate_mainworld_uniqueness(sys, path_prefix)
    count = 0
    count += 1 if sys['mainWorld'].is_a?(Hash)

    counts = sys['counts']
    count += 1 if counts.is_a?(Hash) && counts['mainWorld'].is_a?(Hash)

    (%w[primary] + STAR_LINK_KEYS).each do |key|
      count += star_mainworld_count(sys[key])
    end

    return if count <= 1

    prefix = path_prefix ? "#{path_prefix}: " : ''
    @errors << "#{prefix}mainWorld may only be declared once per star system"
  end

  def star_mainworld_count(star, depth = 0)
    return 0 if star.nil? || !star.is_a?(Hash) || depth > 10

    count = star['mainWorld'].is_a?(Hash) ? 1 : 0

    bodies = star['bodies']
    count += bodies.count { |b| b.is_a?(Hash) && b['mainWorld'] == true } if bodies.is_a?(Array)

    STAR_SCHEMA_CHILD_KEYS.each do |key|
      count += star_mainworld_count(star[key], depth + 1)
    end

    count
  end

  def validate_body_orbits(bodies, path)
    orbits = bodies.select { |b| b.is_a?(Hash) && b['orbit'].present? }
    return if orbits.size <= 1

    @errors << "#{path}.bodies: only one body may specify an orbit label"
  end

  def validate_populated_tech_level
    return if @config['populated'].nil?
    pop = @config['populated']
    check_min_max(pop, 'minTechLevel', 'maxTechLevel', 'minTechLevel must be less than or equal to maxTechLevel')
    %w[before after].each do |region|
      next unless pop[region].is_a?(Hash)
      check_min_max(pop[region], 'minTechLevel', 'maxTechLevel', 'minTechLevel must be less than or equal to maxTechLevel')
    end
  end

  def validate_populated_population
    return if @config['populated'].nil?
    pop = @config['populated']
    check_min_max(pop, 'minPopulationCode', 'maxPopulationCode', 'minPopulationCode must be less than or equal to maxPopulationCode')
    %w[before after].each do |region|
      next unless pop[region].is_a?(Hash)
      check_min_max(pop[region], 'minPopulationCode', 'maxPopulationCode', 'minPopulationCode must be less than or equal to maxPopulationCode')
    end
  end

  def validate_populated_law_level
    return if @config['populated'].nil?
    pop = @config['populated']
    check_min_max(pop, 'minLawLevel', 'maxLawLevel', 'minLawLevel must be less than or equal to maxLawLevel')
    %w[before after].each do |region|
      next unless pop[region].is_a?(Hash)
      check_min_max(pop[region], 'minLawLevel', 'maxLawLevel', 'minLawLevel must be less than or equal to maxLawLevel')
    end
  end

  def validate_populated_allegiance
    return if @config['populated'].nil?
    pop = @config['populated']

    validate_allegiance_code(pop['allegiance']) if pop.key?('allegiance') && !pop['allegiance'].nil?

    %w[before after].each do |region|
      next unless pop[region].is_a?(Hash)
      next unless pop[region].key?('allegiance') && !pop[region]['allegiance'].nil?
      validate_allegiance_code(pop[region]['allegiance'])
    end
  end

  def validate_populated_demarcation
    return if @config['populated'].nil?
    pop = @config['populated']
    demarcation = pop['demarcation']
    return if demarcation.nil?

    if %w[hard-vertical split-vertical].include?(pop['type']) && demarcation > 8
      @errors << 'populated: demarcation must be between 1 and 8 for vertical splits'
    end
  end

  def check_min_max(hash, min_key, max_key, message)
    min = hash[min_key]
    max = hash[max_key]
    return if min.nil? || max.nil?
    @errors << message if min > max
  end

  def validate_allegiance_code(code)
    unless Allegiance.exists?(code: code)
      @errors << "unknown allegiance '#{code}'"
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

  def validate_government_types
    return if @config['populated'].nil?
    pop = @config['populated']

    validate_government_types_list(pop['governmentTypes'])

    %w[before after].each do |region|
      next unless pop[region].is_a?(Hash)
      validate_government_types_list(pop[region]['governmentTypes'])
    end
  end

  def validate_government_types_list(codes)
    return if codes.nil?

    codes.each do |code|
      numeric = government_type_code(code)
      unless numeric && Government.exists?(code: numeric)
        @errors << "unknown government type '#{code}'"
      end
    end
  end

  def government_type_code(code)
    token = code.to_s.strip.upcase
    return nil unless token.length == 1

    HexDigit::HEX_DIGITS.index(token)
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

    main_world = counts['mainWorld']
    if main_world.is_a?(Hash) && main_world['moon'] == true
      gas_giants = counts['gasGiants']
      if gas_giants.nil? || gas_giants < 1
        @errors << "#{path}: gasGiants must be at least 1 when mainWorld moon is true"
      end
    end
  end

  def validate_languages
    check_language(config['language'], 'language')
    systems = Array(config['systems']) + Array(config['required'])
    systems.each_with_index do |sys, idx|
      check_language(sys['language'], "systems[#{idx}].language")
      check_language(sys.dig('counts', 'mainWorld', 'language'), "systems[#{idx}].counts.mainWorld.language")
      (sys.dig('primary', 'bodies') || []).each_with_index do |body, bidx|
        check_language(body['language'], "systems[#{idx}].primary.bodies[#{bidx}].language")
      end
    end
  end

  def check_language(lang, path)
    return if lang.blank?
    return if WordGenerator.languages.map(&:to_s).include?(lang)

    @errors << "#{path}: must be one of #{WordGenerator.languages.join(', ')}"
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
