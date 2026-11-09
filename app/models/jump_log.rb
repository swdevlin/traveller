class JumpLog < ApplicationRecord
  belongs_to :ship
  belongs_to :from_parsec, class_name: 'Parsec'
  belongs_to :to_parsec, class_name: 'Parsec'

  # A jump takes at least this long, unless it was a misjump (which can end
  # anywhere, at any time).
  MINIMUM_TRAVEL_DAYS = 6

  # Survey index a destination is raised to when a ship arrives there.
  DESTINATION_SURVEY_INDEX = 10

  attr_accessor :destination_survey_index

  # Both rules apply to new jumps and to edits that touch the dates, so an old
  # record's notes can still be corrected after the rules were introduced.
  validate :minimum_travel_time, if: :travel_time_changed?
  validate :departure_after_previous_arrival, if: :departure_changed?

  before_create :assign_sequence
  after_save :apply_destination_survey_index, if: -> { destination_survey_index.present? }
  after_create_commit  :queue_map_regeneration
  after_update_commit  :queue_map_regeneration, if: :saved_change_to_to_parsec_id?
  after_destroy_commit :queue_map_regeneration

  after_update :cascade_forward,  if: :arrival_or_destination_changed?
  after_update :cascade_backward, if: :departure_or_origin_changed?

  # Newest first, matching the order of the starmap jump log table.
  def self.newest_first
    order(arrive_year: :desc, arrive_day: :desc, sequence: :desc, id: :desc)
  end

  # The latest jump of this jump's ship. Only that one can be removed without
  # leaving a gap in the ship's route.
  # Arriving somewhere surveys it: raise the destination's survey index to at
  # least this, never lowering it. A star system in the parsec takes it,
  # otherwise the parsec itself (for rogue objects, or an empty hex).
  def raise_destination_survey_index(minimum = DESTINATION_SURVEY_INDEX)
    systems = StarSystem.where(parsec_id: to_parsec_id)

    if systems.exists?
      systems.where('survey_index < ?', minimum).update_all(survey_index: minimum)
    else
      Parsec.where(id: to_parsec_id).where('survey_index IS NULL OR survey_index < ?', minimum)
            .update_all(survey_index: minimum)
    end
  end

  def most_recent_for_ship?
    JumpLog.where(ship_id: ship_id).newest_first.first&.id == id
  end

  def to_s
    date = [arrive_year, arrive_day&.then { |d| format('%03d', d) }].compact.join('-')
    [date.presence, to_parsec&.display_name].compact.join(' – ')
  end

  private

  def dates_present?
    [depart_year, depart_day, arrive_year, arrive_day].none?(&:nil?)
  end

  def travel_time_changed?
    dates_present? && (new_record? || depart_year_changed? || depart_day_changed? ||
                       arrive_year_changed? || arrive_day_changed? || misjump_changed?)
  end

  def departure_changed?
    dates_present? && ship_id.present? &&
      (new_record? || ship_id_changed? || depart_year_changed? || depart_day_changed?)
  end

  def minimum_travel_time
    return if misjump?

    days = date_to_total(arrive_year, arrive_day) - date_to_total(depart_year, depart_day)
    return if days >= MINIMUM_TRAVEL_DAYS

    errors.add(:arrive_day, "must be at least #{MINIMUM_TRAVEL_DAYS} days after departure unless the jump is a misjump")
  end

  def departure_after_previous_arrival
    previous = previous_arrival_total
    return if previous.nil? || date_to_total(depart_year, depart_day) >= previous

    errors.add(:depart_day, "cannot be earlier than the ship's previous arrival (#{format_total(previous)})")
  end

  # The latest arrival of this ship that this jump has to follow, as a day
  # count. For a new jump that is the ship's latest arrival. For an edit it is
  # the arrival of the jump before this one, so earlier jumps can still be edited.
  def previous_arrival_total
    scope = JumpLog.where(ship_id: ship_id)
    scope = scope.where.not(id: id) if persisted?

    if persisted? && !ship_id_changed?
      year = depart_year_was
      day  = depart_day_was
      scope = scope.where('arrive_year < ? OR (arrive_year = ? AND arrive_day <= ?)', year, year, day)
    end

    scope.pluck(:arrive_year, :arrive_day).map { |y, d| date_to_total(y, d) }.max
  end

  def format_total(total)
    format('%<year>d.%<day>03d', year: total / 365 + 1, day: total % 365 + 1)
  end

  def apply_destination_survey_index
    return unless to_parsec
    star_system = to_parsec.star_systems.first
    if star_system
      star_system.update_column(:survey_index, destination_survey_index.to_i)
    else
      to_parsec.update_column(:survey_index, destination_survey_index.to_i)
    end
  end

  def queue_map_regeneration
    campaign = Campaign.find_by(schema_name: Apartment::Tenant.current)
    GenerateAllSectorsMapJob.perform_later(campaign.id) if campaign
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
