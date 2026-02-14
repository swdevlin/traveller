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

  ATMOSPHERE_DESCRIPTIONS = {
    0 => 'None',
    1 => 'Trace',
    2 => 'Very Thin',
    3 => 'Very Thin',
    4 => 'Thin',
    5 => 'Thin',
    6 => 'Standard',
    7 => 'Standard',
    8 => 'Dense',
    9 => 'Dense',
    10 => 'Exotic',
    11 => 'Corrosive',
    12 => 'Insidious',
    13 => 'Very Dense',
    14 => 'Low',
    15 => 'Unusual',
    16 => 'Gas, Helium',
    17 => 'Gas, Hydrogen'
  }.freeze

  def atmosphere_description(code)
    return nil if code.nil?

    ATMOSPHERE_DESCRIPTIONS[code]
  end

  TAINT_DESCRIPTIONS = {
    'L' => 'Low Oxygen',
    'R' => 'Radioactive',
    'B' => 'Biological',
    'G' => 'Gas Mix',
    'P' => 'Particulates',
    'S' => 'Sulphur Compounds',
    'H' => 'High Oxygen'
  }.freeze

  def taint_description(code)
    return if code.blank?

    TAINT_DESCRIPTIONS[code]
  end

  HYDROGRAPHICS_DESCRIPTIONS = {
    0  => '0%–5%',
    1  => '6%–15%',
    2  => '16%–25%',
    3  => '26%–35%',
    4  => '36%–45%',
    5  => '46%–55%',
    6  => '56%–65%',
    7  => '66%–75%',
    8  => '76%–85%',
    9  => '86%–95%',
    10 => '96%–100%'
  }.freeze

  def hydrographics_description(code)
    return if code.blank?

    HYDROGRAPHICS_DESCRIPTIONS[code]
  end

  HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS = {
    0 => 'Extremely Dispersed',
    1 => 'Very Dispersed',
    2 => 'Dispersed',
    3 => 'Scattered',
    4 => 'Slightly Scattered',
    5 => 'Mixed',
    6 => 'Slightly Skewed',
    7 => 'Skewed',
    8 => 'Concentrated',
    9 => 'Very Concentrated',
    10 => 'Extremely Concentrated'
  }.freeze

  def hydrographics_distribution_description(code)
    return if code.blank?

    HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS[code]
  end

  TAINT_SEVERITY_DESCRIPTIONS = {
    1  => 'Trivial irritant',
    2  => 'Surmountable irritant',
    3  => 'Minor irritant',
    4  => 'Major irritant',
    5  => 'Serious irritant',
    6  => 'Hazardous irritant',
    7  => 'Long term lethal',
    8  => 'Inevitably lethal',
    9  => 'Rapidly lethal'
  }.freeze

  def taint_severity_description(code)
    return if code.blank?

    TAINT_SEVERITY_DESCRIPTIONS[code]
  end

  TAINT_PERSISTENCE_DESCRIPTIONS = {
    2  => 'Occasional and brief: Occurs periodically or on a 2D roll of 12 per day and lasts 1D hours',
    3  => 'Occasional and lingering: Occurs periodically or on a 2D roll of 12 per day and lasts 1D days',
    4  => 'Irregular: Occurs on a 2D roll of 9+ and lasts for D3 days',
    5  => 'Fluctuating: roll 2D daily: on 6-, reduce severity by one level; on 12 increase severity by one level',
    6  => 'Varying: Always present but roll 2D daily: on 6-, reduce severity by one level for 1D hours',
    7  => 'Varying: Always present but roll 2D daily: on 4-, reduce severity by one level for 1D hours',
    8  => 'Varying: Always present but roll 2D daily: on 2, reduce severity by one level for 1D hours',
    9  => 'Constant: Ever-present at indicated severity'
  }.freeze

  def taint_persistence_description(code)
    return if code.blank?

    TAINT_PERSISTENCE_DESCRIPTIONS[code]
  end
end
