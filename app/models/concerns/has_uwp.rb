module HasUwp
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_uwp_attributes
    before_validation :sync_uwp, if: :uwp_inputs_changed?
  end

  def atmosphere_code
    atmosphere&.dig('code')
  end

  def atmosphere_code=(val)
    self.atmosphere = (atmosphere || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def atmosphere_composition
    atmosphere&.dig('composition')
  end

  def atmosphere_composition=(val)
    self.atmosphere = (atmosphere || {}).merge('composition' => val.presence)
  end

  def hydrographics_code
    hydrographics&.dig('code')
  end

  def hydrographics_code=(val)
    self.hydrographics = (hydrographics || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def hydrographics_liquid
    hydrographics&.dig('liquid')
  end

  def hydrographics_liquid=(val)
    self.hydrographics = (hydrographics || {}).merge('liquid' => val.presence)
  end

  def hydrographics_distribution
    hydrographics&.dig('distribution')
  end

  def hydrographics_distribution=(val)
    self.hydrographics = (hydrographics || {}).merge('distribution' => val.present? ? val.to_i : nil)
  end

  def population_code
    population&.dig('code')
  end

  def population_code=(val)
    self.population = (population || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def population_concentration_rating
    population&.dig('concentrationRating')
  end

  def population_concentration_rating=(val)
    self.population = (population || {}).merge('concentrationRating' => val.present? ? val.to_i : nil)
  end

  def population_urbanization_percentage
    population&.dig('urbanizationPercentage')
  end

  def population_urbanization_percentage=(val)
    self.population = (population || {}).merge('urbanizationPercentage' => val.present? ? val.to_i : nil)
  end

  def population_major_cities
    population&.dig('majorCities')
  end

  def population_major_cities=(val)
    self.population = (population || {}).merge('majorCities' => val.present? ? val.to_i : nil)
  end

  def government_code
    government&.dig('code')
  end

  def government_code=(val)
    self.government = (government || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def starport_code
    data&.dig('starport_code')
  end

  def starport_code=(val)
    self.data = (data || {}).merge('starport_code' => val.presence)
  end

  module ClassMethods
    def uwp_attribute_names
      [
        :atmosphere_code, :atmosphere_composition,
        :hydrographics_code, :hydrographics_liquid, :hydrographics_distribution,
        :population_code, :population_concentration_rating, :population_urbanization_percentage, :population_major_cities,
        :government_code, :law_level_code,
        :starport_code,
        :tech_level_code
      ]
    end
  end

  private

  def sync_uwp
    self.uwp = [
      starport_code || 'X',
      size_code || '0',
      HexDigit.hex_digit(atmosphere_code),
      HexDigit.hex_digit(hydrographics_code),
      HexDigit.hex_digit(population_code),
      HexDigit.hex_digit(government_code),
      HexDigit.hex_digit(law_level_code),
      '-',
      HexDigit.hex_digit(tech_level_code)
    ].join
  end

  def normalize_uwp_attributes
    self.law_level_code = law_level_code.to_i if law_level_code.present?
  end

  def uwp_inputs_changed?
    will_save_change_to_size_code? || will_save_change_to_data?
  end
end
