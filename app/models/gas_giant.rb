class GasGiant < StellarObject
  include GeneratorMappings

  before_validation :normalize_data_types

  generator_data_map(
    diameter: 'diameter',
    code: 'code',
    period: 'period',
    rotation: 'rotation'
  )

  def self.permitted_params
    [
      :name, :notes, :orbit, :inclination, :eccentricity, :diameter, :mass,
      data: [:code, :period, :rotation]
    ]
  end

  private

  def normalize_data_types
    self.period = period.to_f if period.present?
    self.rotation = rotation.to_f if rotation.present?
  end
end
