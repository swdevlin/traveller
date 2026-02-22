module HasUwpAttributes
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_uwp_attributes
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

  def starport_code
    data&.dig('starport_code')
  end

  def starport_code=(val)
    self.data = (data || {}).merge('starport_code' => val.presence)
  end

  module ClassMethods
    def uwp_permitted_params
      [
        :atmosphere_code, :atmosphere_composition,
        :hydrographics_code, :hydrographics_liquid, :hydrographics_distribution,
        :population_code,
        :government_code, :law_level_code,
        :starport_code,
        :tech_level_code
      ]
    end
  end

  private

  def normalize_uwp_attributes
    self.government_code = government_code.to_i if government_code.present?
    self.law_level_code = law_level_code.to_i if law_level_code.present?
  end
end
