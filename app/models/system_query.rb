class SystemQuery < ApplicationRecord
  include HasFilterRule

  # `jump_route` is a SystemQuery-only field, not shared via HasFilterRule —
  # SurveyOverlay (the other includer, for map-highlight rules) has its own
  # separate field_value dispatch with no jump_route case, and no Elm-side
  # HighlightRule.elm support either, so surfacing it there would add a
  # silently-dead option to the overlay editor.
  FIELDS = (HasFilterRule::FIELDS + [['jump_route', 'Jump Route']]).sort_by(&:first).freeze
  OPERATORS_FOR_FIELD = HasFilterRule::OPERATORS_FOR_FIELD.merge('jump_route' => %w[eq one_of]).freeze

  def self.jump_route_options
    JumpRoute.order(:name).pluck(:id, :name).map { |id, name| [id.to_s, name] }
  end

  def self.picker_options
    super.merge('jump_route' => jump_route_options)
  end

  # Sector+location (e.g. "Bifront 0307") and name always identify the row,
  # so they're not part of the referee's choosable set — always shown,
  # always in this order, first.
  MANDATORY_COLUMNS = %w[sector_location name].freeze

  # Order here drives both the checkbox layout on the query form and the
  # render order of the results table (see `display_columns`).
  COLUMN_KEYS = %w[uwp trade_codes bases zone stars allegiance survey_index locked].freeze

  COLUMN_LABELS = {
    'bases' => 'Bases', 'locked' => 'Locked', 'uwp' => 'UWP',
    'trade_codes' => 'Trade codes', 'stars' => 'Stars', 'allegiance' => 'Allegiance',
    'zone' => 'Zone', 'survey_index' => 'Survey Index'
  }.freeze

  validates :name, presence: true
  validate :columns_are_known

  def matching_star_systems(base_scope = StarSystem.all)
    SystemQueryBuilder.new(rule_data).relation(base_scope)
  end

  # The full column set to render, with the mandatory sector/name/location
  # prefix always first regardless of what's stored.
  def display_columns
    MANDATORY_COLUMNS + (COLUMN_KEYS & columns)
  end

  private

  def columns_are_known
    return if columns.is_a?(Array) && columns.all? { |c| COLUMN_KEYS.include?(c) }

    errors.add(:columns, 'must be a subset of the known display columns')
  end
end
