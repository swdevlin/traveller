module StellarObjectsHelper
  # Converts Kelvin to Celsius
  def kelvin_to_celsius(kelvin)
    return nil if kelvin.nil?

    kelvin - StellarConstants::KELVIN_TO_CELSIUS_OFFSET
  end

  # Formats temperature in Celsius with appropriate precision
  def format_temperature_celsius(kelvin)
    return nil if kelvin.nil?

    celsius = kelvin_to_celsius(kelvin)
    number_with_precision(celsius, precision: 0)
  end

  def temperature_label(temperature)
    return '' if temperature.nil?
    if temperature > 313.15
      'Hot'
    elsif temperature < 273.15
      'Freezing'
    end
  end

  # Calculates flip-and-burn travel time (accelerate halfway, decelerate halfway)
  # distance_km: distance in kilometers
  # g_rating: maneuver drive G rating (1-6)
  # Returns time in hours
  def flip_burn_travel_time_hours(distance_km, g_rating)
    return nil if distance_km.nil? || distance_km <= 0 || g_rating.nil? || g_rating <= 0

    distance_m = distance_km * 1000.0
    acceleration = g_rating * 9.81 # m/s²
    time_seconds = 2.0 * Math.sqrt(distance_m / acceleration)
    time_seconds / 3600.0
  end

  # Formats travel time as hours or days depending on magnitude
  def format_travel_time(hours)
    return '-' if hours.nil?

    if hours < 24
      "#{number_with_precision(hours, precision: 1, strip_insignificant_zeros: true)}h"
    else
      days = hours / 24.0
      "#{number_with_precision(days, precision: 1, strip_insignificant_zeros: true)}d"
    end
  end

  # Returns a hash of G rating => formatted travel time
  def jump_shadow_travel_times(distance_km)
    (1..6).to_h do |g|
      hours = flip_burn_travel_time_hours(distance_km, g)
      [g, format_travel_time(hours)]
    end
  end

  def biodiversity_description(rating)
    return nil if rating.nil?

    if rating >= 10
      'Complexity equivalent to pre-human Terra'
    elsif rating < 3
      'Very uniform biosphere'
    else
      'Moderate species diversity'
    end
  end

  RESOURCE_RATING_DESCRIPTIONS = {
    2 => 'No economically extractable resources',
    3 => 'Marginal at best',
    4 => 'Marginal at best',
    5 => 'Marginal at best',
    6 => 'Worthwhile with considerable effort',
    7 => 'Worthwhile with considerable effort',
    8 => 'Worthwhile with considerable effort',
    9 => 'Priority target',
    10 => 'Priority target',
    11 => 'Liable to experience a resource rush',
    12 => 'Liable to experience a resource rush'
  }.freeze

  def resource_rating_description(rating)
    return nil if rating.nil?

    RESOURCE_RATING_DESCRIPTIONS[rating]
  end

  BIOCOMPLEXITY_DESCRIPTIONS = {
    1 => 'Primitive single-cell organisms',
    2 => 'Advanced cellular organisms',
    3 => 'Primitive multicellular organisms',
    4 => 'Differentiated multicellular organisms',
    5 => 'Complex multicellular organisms',
    6 => 'Advanced multicellular organisms',
    7 => 'Socially advanced organisms',
    8 => 'Mentally advanced organisms',
    9 => 'Extant or extinct sophonts',
    10 => 'Ecosystem-wide superorganisms'
  }.freeze

  def biocomplexity_description(rating)
    return nil if rating.nil?

    BIOCOMPLEXITY_DESCRIPTIONS[rating]
  end
end
