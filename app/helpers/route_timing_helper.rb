# frozen_string_literal: true

module RouteTimingHelper
  def format_duration_hours(hours)
    return '-' if hours.nil?

    total_minutes = (hours * 60).round
    return "#{total_minutes}m" if total_minutes < 60

    total_hours = total_minutes / 60
    return "#{total_hours}h #{total_minutes - (total_hours * 60)}m" if total_hours < 24

    weeks           = total_hours / 168
    days            = (total_hours % 168) / 24
    hours_remainder = total_hours % 24

    [("#{weeks}w" if weeks.positive?), ("#{days}d" if days.positive?), "#{hours_remainder}h"].compact.join(' ')
  end

  def format_duration_range(min_hours, avg_hours, max_hours)
    "#{format_duration_hours(avg_hours)} (±#{format_duration_hours((max_hours - min_hours) / 2.0)})"
  end
end
