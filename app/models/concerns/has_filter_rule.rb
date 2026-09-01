module HasFilterRule
  extend ActiveSupport::Concern

  def self.codes_up_to(max_code)
    HexDigit::HEX_DIGITS[0..max_code].chars
  end

  FIELDS = [
    ['allegiance', 'Allegiance'],
    ['atmosphere', 'Atmosphere'],
    ['base_count', 'Base Count'],
    ['bases', 'Bases'],
    ['extinct_sophont', 'Extinct Sophont'],
    ['gas_giant_count', 'Gas Giants'],
    ['government', 'Government'],
    ['hydrographics', 'Hydrographics'],
    ['importance', 'Importance'],
    ['known', 'Known'],
    ['law_level', 'Law Level'],
    ['native_sophont', 'Native Sophont'],
    ['planetoid_belt_count', 'Planetoid Belts'],
    ['population', 'Population'],
    ['primary_star', 'Primary Star'],
    ['primary_star_class', 'Primary Star Class'],
    ['sector', 'Sector'],
    ['size', 'Size'],
    ['star_count', 'Star Count'],
    ['starport', 'Starport'],
    ['subsector', 'Subsector'],
    ['survey_index', 'Survey Index'],
    ['tech_level', 'Tech Level']
  ].freeze

  OPERATORS = [
    ['eq', 'is'],
    ['lt', 'less than'],
    ['lte', 'less than or equal to'],
    ['gt', 'greater than'],
    ['gte', 'greater than or equal to'],
    ['between', 'between'],
    ['one_of', 'one of'],
    ['has', 'has'],
    ['has_one_of', 'has one of']
  ].freeze

  # Boolean fields only ever make sense as an equality check; Bases is
  # list-valued so it only supports containment checks.
  OPERATORS_FOR_FIELD = {
    'known'           => %w[eq],
    'native_sophont'  => %w[eq],
    'extinct_sophont' => %w[eq],
    'bases'           => %w[has has_one_of],
    'allegiance'      => %w[eq one_of],
    'sector'          => %w[eq one_of],
    'subsector'       => %w[eq one_of],
    'primary_star'    => %w[eq one_of]
  }.freeze

  # The valid (code, label) options for each field, mirroring
  # `HighlightRule.elm`'s `fieldOptions` — this drives both the value
  # picker in the form and the validation domain below. `bases` is
  # intentionally omitted here — its options come live from the
  # referee-editable `Facility` table, not a fixed enum; see
  # `bases_options`/the dedicated `Facility.exists?` check below.
  FIELD_OPTIONS = {
    'starport'              => %w[A B C D E X].map { |c| [c, c] },
    'size'                  => codes_up_to(15).map { |c| [c, c] },
    'atmosphere'            => codes_up_to(17).map { |c| [c, c] },
    'hydrographics'         => codes_up_to(10).map { |c| [c, c] },
    'population'            => codes_up_to(12).map { |c| [c, c] },
    'government'            => codes_up_to(15).map { |c| [c, c] },
    'law_level'             => codes_up_to(18).map { |c| [c, c] },
    'tech_level'            => codes_up_to(16).map { |c| [c, c] },
    'survey_index'          => (0..12).map { |n| [n.to_s, n.to_s] },
    'known'                 => [%w[true Yes], %w[false No]],
    'gas_giant_count'       => (0..10).map { |n| [n.to_s, n.to_s] },
    'planetoid_belt_count'  => (0..10).map { |n| [n.to_s, n.to_s] },
    'native_sophont'        => [%w[true Yes], %w[false No]],
    'extinct_sophont'       => [%w[true Yes], %w[false No]],
    'importance'            => (-3..5).map { |n| [n.to_s, n.to_s] },
    'base_count'            => (0..10).map { |n| [n.to_s, n.to_s] },
    'star_count'            => (1..8).map { |n| [n.to_s, n.to_s] },
    'primary_star'          => %w[O B A F G K M].map { |c| [c, c] } +
                                [['L', 'L Dwarf'], ['T', 'T Dwarf'], ['Y', 'Y Dwarf']] +
                                Star::SPECIAL_SPECTRAL_TYPES.to_a,
    'primary_star_class'    => [
      ['0', '0 (Hypergiant)'], ['Ia', 'Ia (Luminous supergiant)'],
      ['Iab', 'Iab (Intermediate supergiant)'], ['Ib', 'Ib (Less luminous supergiant)'],
      ['II', 'II (Bright giant)'], ['III', 'III (Giant)'], ['IV', 'IV (Subgiant)'],
      ['V', 'V (Main sequence)'], ['VI', 'VI (Subdwarf)'], ['VII', 'VII (White dwarf)']
    ]
  }.freeze

  class_methods do
    def bases_options
      Facility.order(:code).pluck(:code, :name)
    end

    # Allegiance/Sector/Subsector are, like Bases, referee-editable rows in
    # their own tables rather than a fixed enum, so their options are sourced
    # live rather than listed in FIELD_OPTIONS. Sector/Subsector have no short
    # `code` column, so the row's id is used as the rule value instead.
    def allegiance_options
      Allegiance.order(:code).pluck(:code, :name)
    end

    def sector_options
      Sector.kept.order(:name).pluck(:id, :name).map { |id, name| [id.to_s, name] }
    end

    def subsector_options
      Subsector.kept_sector.joins(:sector).order('sectors.name, subsectors.name')
               .pluck(:id, :name, 'sectors.name')
               .map { |id, name, sector_name| [id.to_s, "#{name} (#{sector_name})"] }
    end

    # Every field's (code, label) options in one place, for driving the
    # per-field value picker in the form.
    def picker_options
      FIELD_OPTIONS.merge(
        'bases'      => bases_options,
        'allegiance' => allegiance_options,
        'sector'     => sector_options,
        'subsector'  => subsector_options
      )
    end

    def field_label(code)
      FIELDS.find { |value, _| value == code }&.last || code
    end

    def operator_label(code)
      OPERATORS.find { |value, _| value == code }&.last || code
    end
  end

  included do
    validate :rule_data_shape_is_valid
  end

  def groups
    (rule_data['groups'] || rule_data[:groups] || []).map do |group|
      group.map { |condition| condition.symbolize_keys }
    end
  end

  private

  def rule_data_shape_is_valid
    unless rule_data.is_a?(Hash)
      errors.add(:rule_data, 'must be an object')
      return
    end

    groups = rule_data['groups'] || rule_data[:groups]
    return if groups.nil? # no conditions defined yet is a valid, empty rule

    unless groups.is_a?(Array)
      errors.add(:rule_data, 'must have a "groups" array')
      return
    end

    groups.each_with_index do |group, group_index|
      unless group.is_a?(Array)
        errors.add(:rule_data, "group #{group_index + 1} must be an array of conditions")
        next
      end

      group.each_with_index do |condition, condition_index|
        validate_condition(condition, group_index, condition_index)
      end
    end
  end

  def validate_condition(condition, group_index, condition_index)
    label = "condition #{condition_index + 1} in group #{group_index + 1}"

    unless condition.is_a?(Hash)
      errors.add(:rule_data, "#{label} must be an object")
      return
    end

    field = condition['field'] || condition[:field]
    operator = condition['operator'] || condition[:operator]
    values = condition['values'] || condition[:values]

    unless self.class::FIELDS.map(&:first).include?(field)
      errors.add(:rule_data, "#{label} has an unknown field")
      return
    end

    allowed_operators = self.class::OPERATORS_FOR_FIELD.fetch(field, self.class::OPERATORS.map(&:first))
    unless allowed_operators.include?(operator)
      errors.add(:rule_data, "#{label} has an unknown or unsupported operator")
      return
    end

    unless values.is_a?(Array) && values.all? { |value| value.is_a?(String) }
      errors.add(:rule_data, "#{label} must have a \"values\" array of strings")
      return
    end

    case operator
    when 'between'
      errors.add(:rule_data, "#{label} must have exactly 2 values for \"between\"") unless values.size == 2
    else
      errors.add(:rule_data, "#{label} must have at least 1 value") if values.empty?
    end

    case field
    when 'bases'
      errors.add(:rule_data, "#{label} has an unknown base code") if values.any? { |value| !Facility.exists?(code: value) }
    when 'allegiance'
      errors.add(:rule_data, "#{label} has an unknown allegiance") if values.any? { |value| !Allegiance.exists?(code: value) }
    when 'sector'
      errors.add(:rule_data, "#{label} has an unknown sector") if values.any? { |value| !Sector.kept.exists?(id: value) }
    when 'subsector'
      errors.add(:rule_data, "#{label} has an unknown subsector") if values.any? { |value| !Subsector.kept_sector.exists?(id: value) }
    else
      domain = self.class::FIELD_OPTIONS[field]&.map(&:first)
      if domain && values.any? { |value| !domain.include?(value) }
        errors.add(:rule_data, "#{label} has an invalid value for #{self.class.field_label(field)}")
      end
    end
  end
end
