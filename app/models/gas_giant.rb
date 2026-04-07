class GasGiant < StellarObject
  include GeneratorMappings

  SIZES = { 'GS' => 'Small', 'GM' => 'Medium', 'GL' => 'Large' }.freeze

  after_initialize :normalize_data_types
  before_validation :normalize_data_types

  generator_data_map(
    diameter: 'diameter',
    code: 'code',
    period: 'period',
    rotation: 'rotation',
    axial_tilt: 'axialTilt',
    tidal_lock: 'tidalLock',
    tidal_lock_note: 'tidalLockNote',
    twilight_zone: 'twilightZone',
    sidereal_day: 'siderealDay'
  )

  def orbit_type = 10

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
