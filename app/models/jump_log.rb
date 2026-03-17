class JumpLog < ApplicationRecord
  belongs_to :ship
  belongs_to :from_parsec, class_name: 'Parsec'
  belongs_to :to_parsec, class_name: 'Parsec'

  attr_accessor :destination_survey_index

  before_create :assign_sequence
  after_save :apply_destination_survey_index, if: -> { destination_survey_index.present? }

  after_update :cascade_forward,  if: :arrival_or_destination_changed?
  after_update :cascade_backward, if: :departure_or_origin_changed?

  def to_s
    date = [arrive_year, arrive_day&.then { |d| format('%03d', d) }].compact.join('-')
    [date.presence, to_parsec&.display_name].compact.join(' – ')
  end

  private

  def apply_destination_survey_index
    return unless to_parsec
    star_system = to_parsec.star_systems.first
    if star_system
      star_system.update_column(:survey_index, destination_survey_index.to_i)
    else
      to_parsec.update_column(:survey_index, destination_survey_index.to_i)
    end
  end

  def assign_sequence
    self.sequence = (JumpLog.maximum(:sequence) || 0) + 1
  end

  def arrival_or_destination_changed?
    saved_change_to_arrive_year? || saved_change_to_arrive_day? || saved_change_to_to_parsec_id?
  end

  def departure_or_origin_changed?
    saved_change_to_depart_year? || saved_change_to_depart_day? || saved_change_to_from_parsec_id?
  end

  def cascade_forward
    old_arrive_year, new_arrive_year = saved_changes.fetch('arrive_year', [arrive_year, arrive_year])
    old_arrive_day,  new_arrive_day  = saved_changes.fetch('arrive_day',  [arrive_day,  arrive_day])
    _old_to, new_to_parsec_id        = saved_changes.fetch('to_parsec_id', [to_parsec_id, to_parsec_id])

    after_scope = JumpLog
      .where(ship_id: ship_id)
      .where.not(id: id)
      .where(
        'depart_year > ? OR (depart_year = ? AND depart_day >= ?)',
        old_arrive_year, old_arrive_year, old_arrive_day
      )

    if saved_change_to_to_parsec_id?
      after_scope.order(:depart_year, :depart_day).limit(1)
                 .update_all(from_parsec_id: new_to_parsec_id)
    end

    if saved_change_to_arrive_year? || saved_change_to_arrive_day?
      delta = date_to_total(new_arrive_year, new_arrive_day) -
              date_to_total(old_arrive_year, old_arrive_day)
      after_scope.update_all(date_shift_sql(delta))
    end
  end

  def cascade_backward
    old_depart_year, new_depart_year = saved_changes.fetch('depart_year', [depart_year, depart_year])
    old_depart_day,  new_depart_day  = saved_changes.fetch('depart_day',  [depart_day,  depart_day])
    _old_from, new_from_parsec_id    = saved_changes.fetch('from_parsec_id', [from_parsec_id, from_parsec_id])

    before_scope = JumpLog
      .where(ship_id: ship_id)
      .where.not(id: id)
      .where(
        'arrive_year < ? OR (arrive_year = ? AND arrive_day <= ?)',
        old_depart_year, old_depart_year, old_depart_day
      )

    if saved_change_to_from_parsec_id?
      before_scope.order(arrive_year: :desc, arrive_day: :desc).limit(1)
                  .update_all(to_parsec_id: new_from_parsec_id)
    end

    if saved_change_to_depart_year? || saved_change_to_depart_day?
      delta = date_to_total(new_depart_year, new_depart_day) -
              date_to_total(old_depart_year, old_depart_day)
      before_scope.update_all(date_shift_sql(delta))
    end
  end

  def date_to_total(year, day)
    (year - 1) * 365 + (day - 1)
  end

  def date_shift_sql(delta)
    [
      'depart_year = ((depart_year - 1) * 365 + (depart_day - 1) + ?) / 365 + 1, ' \
      'depart_day  = ((depart_year - 1) * 365 + (depart_day - 1) + ?) % 365 + 1, ' \
      'arrive_year = ((arrive_year - 1) * 365 + (arrive_day - 1) + ?) / 365 + 1, ' \
      'arrive_day  = ((arrive_year - 1) * 365 + (arrive_day - 1) + ?) % 365 + 1',
      delta, delta, delta, delta
    ]
  end
end
