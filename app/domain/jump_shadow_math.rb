# frozen_string_literal: true

module JumpShadowMath
  # Calculates flip-and-burn travel time (accelerate halfway, decelerate halfway).
  # distance_km: distance in kilometres
  # g_rating: maneuver drive G rating (1-6)
  # Returns time in hours.
  def flip_burn_travel_time_hours(distance_km, g_rating)
    return nil if distance_km.nil? || distance_km <= 0 || g_rating.nil? || g_rating <= 0

    distance_m = distance_km * 1000.0
    acceleration = g_rating * 9.81 # m/s²
    time_seconds = 2.0 * Math.sqrt(distance_m / acceleration)
    time_seconds / 3600.0
  end

  # Formats travel time as hours or days depending on magnitude.
  def format_travel_time(hours)
    return '-' if hours.nil?

    if hours < 24
      "#{number_with_precision(hours, precision: 1, strip_insignificant_zeros: true)}h"
    else
      days = hours / 24.0
      "#{number_with_precision(days, precision: 1, strip_insignificant_zeros: true)}d"
    end
  end

  # Returns a hash of G rating => formatted travel time.
  def jump_shadow_travel_times(distance_km)
    (1..6).to_h do |g|
      [g, format_travel_time(flip_burn_travel_time_hours(distance_km, g))]
    end
  end
end
