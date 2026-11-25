# frozen_string_literal: true

# The referee's request to advance a star system's orbits (see OrbitAdvancer). Negative days rewind.
class OrbitAdvance
  include ActiveModel::Model
  include ActiveModel::Attributes

  MAX_DAYS = 3_650_000

  attribute :days, :integer

  validates :days, presence: true,
                   numericality: { only_integer: true, other_than: 0, greater_than_or_equal_to: -MAX_DAYS,
                                   less_than_or_equal_to: MAX_DAYS }
end
