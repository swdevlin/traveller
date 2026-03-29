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

  include JumpShadowMath

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

  POPULATION_RANGES = {
    0  => '0',
    1  => '1 – 99',
    2  => '100 – 999',
    3  => '1,000 – 9,999',
    4  => '10,000 – 99,999',
    5  => '100,000 – 999,999',
    6  => '1,000,000 – 9,999,999',
    7  => '10,000,000 – 99,999,999',
    8  => '100,000,000 – 999,999,999',
    9  => '1,000,000,000 – 9,999,999,999',
    10 => '10,000,000,000 – 99,999,999,999',
    11 => '100,000,000,000 – 999,999,999,999',
    12 => '1,000,000,000,000 – 9,999,999,999,999'
  }.freeze

  def population_range(code)
    return nil if code.nil?

    POPULATION_RANGES[code.to_i]
  end

  CONCENTRATION_RATING_DESCRIPTIONS = {
    0 => 'Extremely Dispersed',
    1 => 'Highly Dispersed',
    2 => 'Moderately Dispersed',
    3 => 'Partially Dispersed',
    4 => 'Slightly Dispersed',
    5 => 'Slightly Concentrated',
    6 => 'Partially Concentrated',
    7 => 'Moderately Concentrated',
    8 => 'Highly Concentrated',
    9 => 'Extremely Concentrated'
  }.freeze

  def concentration_rating_description(rating)
    return nil if rating.nil?

    CONCENTRATION_RATING_DESCRIPTIONS[rating.to_i]
  end

  STARPORT_CODES = {
    'A' => 'Excellent',
    'B' => 'Good',
    'C' => 'Routine',
    'D' => 'Poor',
    'E' => 'Frontier',
    'X' => 'None'
  }.freeze

  SIZE_DESCRIPTIONS = {
    '0'  => 'Belt',
    'S'  => '600 km',
    '1'  => '1,600 km',
    '2'  => '3,200 km',
    '3'  => '4,800 km',
    '4'  => '6,400 km',
    '5'  => '8,000 km',
    '6'  => '9,600 km',
    '7'  => '11,200 km',
    '8'  => '12,800 km',
    '9'  => '14,400 km',
    'A' => '16,000 km',
    'B' => '17,600 km',
    'C' => '19,200 km',
    'D' => '20,800 km',
    'E' => '22,400 km',
    'F' => '24,000 km'
  }.freeze

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
