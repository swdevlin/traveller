class JumpLog < ApplicationRecord
  belongs_to :ship
  belongs_to :from_parsec, class_name: 'Parsec'
  belongs_to :to_parsec, class_name: 'Parsec'

  before_create :assign_sequence

  def to_s
    date = [arrive_year, arrive_day&.then { |d| format('%03d', d) }].compact.join('-')
    [date.presence, to_parsec&.display_name].compact.join(' – ')
  end

  private

  def assign_sequence
    self.sequence = (JumpLog.maximum(:sequence) || 0) + 1
  end
end
