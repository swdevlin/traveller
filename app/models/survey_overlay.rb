class SurveyOverlay < ApplicationRecord
  include HasHexColour

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
    ['sector', 'Sector'],
    ['size', 'Size'],
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
  # list-valued so it only supports containment checks. Mirrors
  # `HighlightRule.elm`'s `operatorsFor`.
  OPERATORS_FOR_FIELD = {
    'known'           => %w[eq],
    'native_sophont'  => %w[eq],
    'extinct_sophont' => %w[eq],
    'bases'           => %w[has has_one_of],
    'allegiance'      => %w[eq one_of],
    'sector'          => %w[eq one_of],
    'subsector'       => %w[eq one_of]
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
    'base_count'            => (0..10).map { |n| [n.to_s, n.to_s] }
  }.freeze

  def self.bases_options
    Facility.order(:code).pluck(:code, :name)
  end

  # Allegiance/Sector/Subsector are, like Bases, referee-editable rows in
  # their own tables rather than a fixed enum, so their options are sourced
  # live rather than listed in FIELD_OPTIONS. Sector/Subsector have no short
  # `code` column, so the row's id is used as the rule value instead.
  def self.allegiance_options
    Allegiance.order(:code).pluck(:code, :name)
  end

  def self.sector_options
    Sector.kept.order(:name).pluck(:id, :name).map { |id, name| [id.to_s, name] }
  end

  def self.subsector_options
    Subsector.kept_sector.joins(:sector).order('sectors.name, subsectors.name')
             .pluck(:id, :name, 'sectors.name')
             .map { |id, name, sector_name| [id.to_s, "#{name} (#{sector_name})"] }
  end

  # Every field's (code, label) options in one place, for driving the
  # per-field value picker in the form.
  def self.picker_options
    FIELD_OPTIONS.merge(
      'bases'      => bases_options,
      'allegiance' => allegiance_options,
      'sector'     => sector_options,
      'subsector'  => subsector_options
    )
  end

  validates :name, presence: true
  validates_hex_colour :colour, presence: true
  validate :rule_data_shape_is_valid

  before_validation :assign_position, on: :create

  scope :ordered, -> { order(:position) }

  def self.field_label(code)
    FIELDS.find { |value, _| value == code }&.last || code
  end

  def self.operator_label(code)
    OPERATORS.find { |value, _| value == code }&.last || code
  end

  def groups
    (rule_data['groups'] || rule_data[:groups] || []).map do |group|
      group.map { |condition| condition.symbolize_keys }
    end
  end

  # The colour of the first enabled, matching overlay (in list order), if
  # any. Mirrors `Traveller.HighlightRule.matchColour` — callers pass an
  # already enabled-filtered, position-ordered array.
  def self.colour_for(star_system, overlays)
    overlays.find { |overlay| overlay.matches?(star_system) }&.colour
  end

  # A rule matches a system if any one of its groups has every condition
  # matching. Mirrors `Traveller.HighlightRule.evaluate`.
  def matches?(star_system)
    groups.any? { |group| group.all? { |condition| condition_matches?(condition, star_system) } }
  end

  def move_up!
    swap_with_adjacent(SurveyOverlay.ordered.where('position < ?', position).last)
  end

  def move_down!
    swap_with_adjacent(SurveyOverlay.ordered.where('position > ?', position).first)
  end

  private

  # Mirrors `Traveller.HighlightRule.conditionMatches`.
  def condition_matches?(condition, star_system)
    result = evaluate_condition(condition, star_system)
    condition[:negate] ? !result : result
  end

  def evaluate_condition(condition, star_system)
    field = condition[:field]
    operator = condition[:operator]
    values = condition[:values] || []

    return bases_condition_matches?(operator, values, star_system) if field == 'bases'

    code = field_value(field, star_system)
    return false if code.nil?

    case operator
    when 'eq'      then code == values.first
    when 'one_of'  then values.include?(code)
    when 'lt', 'lte', 'gt', 'gte'
      compare_rank(field, code, values.first, operator)
    when 'between'
      values.size == 2 && compare_between(field, code, values[0], values[1])
    else
      false
    end
  end

  def bases_condition_matches?(operator, values, star_system)
    base_codes = star_system.facilities.map(&:code)
    case operator
    when 'has'         then values.first.present? && base_codes.include?(values.first)
    when 'has_one_of'  then (base_codes & values).any?
    else false
    end
  end

  # Mirrors `Traveller.HighlightRule.getFieldValue`/`parseUwp` — UWP
  # characters are used directly (not hex-decoded), since `FIELD_OPTIONS`
  # codes are the same alphabet characters.
  def field_value(field, star_system)
    case field
    when 'starport'      then star_system.main_world_uwp&.[](0)
    when 'size'           then star_system.main_world_uwp&.[](1)
    when 'atmosphere'      then star_system.main_world_uwp&.[](2)
    when 'hydrographics'   then star_system.main_world_uwp&.[](3)
    when 'population'      then star_system.main_world_uwp&.[](4)
    when 'government'      then star_system.main_world_uwp&.[](5)
    when 'law_level'       then star_system.main_world_uwp&.[](6)
    when 'tech_level'      then star_system.main_world_uwp&.[](8)
    when 'survey_index'    then star_system.survey_index.to_s
    when 'known'           then star_system.known?.to_s
    when 'gas_giant_count' then star_system.gas_giant_count.to_s
    when 'planetoid_belt_count' then star_system.belt_count.to_s
    when 'native_sophont'  then (!!star_system.native_sophont).to_s
    when 'extinct_sophont' then (!!star_system.extinct_sophont).to_s
    when 'importance'      then star_system.main_world_importance&.to_s
    when 'base_count'      then star_system.facilities.size.to_s
    when 'allegiance'      then star_system.allegiance&.code
    when 'sector'          then star_system.parsec.sector_id.to_s
    when 'subsector'       then star_system.parsec.subsector&.id&.to_s
    end
  end

  # Each field's rank is its index in `FIELD_OPTIONS`, reversed for
  # `starport` since A is the best starport, X the worst. Mirrors
  # `Traveller.HighlightRule.fieldRank`.
  def field_rank(field, code)
    options = FIELD_OPTIONS[field]&.map(&:first)
    return nil unless options

    index = options.index(code)
    return nil unless index

    field == 'starport' ? options.size - 1 - index : index
  end

  def compare_rank(field, code, target, operator)
    a = field_rank(field, code)
    b = field_rank(field, target)
    return false if a.nil? || b.nil?

    case operator
    when 'lt'  then a < b
    when 'lte' then a <= b
    when 'gt'  then a > b
    when 'gte' then a >= b
    end
  end

  def compare_between(field, code, lo, hi)
    c = field_rank(field, code)
    a = field_rank(field, lo)
    b = field_rank(field, hi)
    return false if c.nil? || a.nil? || b.nil?

    low, high = [a, b].minmax
    c >= low && c <= high
  end

  def assign_position
    self.position ||= (SurveyOverlay.maximum(:position) || 0) + 1
  end

  def swap_with_adjacent(other)
    return unless other

    SurveyOverlay.transaction do
      my_position = position
      update!(position: other.position)
      other.update!(position: my_position)
    end
  end

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

    unless FIELDS.map(&:first).include?(field)
      errors.add(:rule_data, "#{label} has an unknown field")
      return
    end

    allowed_operators = OPERATORS_FOR_FIELD.fetch(field, OPERATORS.map(&:first))
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
      domain = FIELD_OPTIONS[field]&.map(&:first)
      if domain && values.any? { |value| !domain.include?(value) }
        errors.add(:rule_data, "#{label} has an invalid value for #{self.class.field_label(field)}")
      end
    end
  end
end
