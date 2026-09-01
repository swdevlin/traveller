class SurveyOverlay < ApplicationRecord
  include HasHexColour
  include HasFilterRule

  validates :name, presence: true
  validates_hex_colour :colour, presence: true

  before_validation :assign_position, on: :create

  scope :ordered, -> { order(:position) }

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
    when 'star_count'      then star_system.stars.size.to_s
    when 'primary_star'       then star_system.primary_star&.stellar_type
    when 'primary_star_class' then star_system.primary_star&.stellar_class
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
end
