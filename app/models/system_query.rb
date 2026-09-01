class SystemQuery < ApplicationRecord
  include HasFilterRule

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
