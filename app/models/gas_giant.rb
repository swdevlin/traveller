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

  # The starmap (Elm) decoder cannot load a gas giant without these, so every new one must supply them.
  validates :orbit, :inclination, :eccentricity, :diameter, :period, :axial_tilt, :code, presence: true, on: :manual
  validates :code, inclusion: { in: SIZES.keys }, allow_blank: true

  def orbit_type = 10

  def self.allowed_data_keys
    [:size]
  end

  def self.permitted_params
    [
      :name, :player_notes, :referee_notes, :tag_list, :reference_url, :orbit, :inclination, :eccentricity, :diameter, :mass,
      data: [:code, :period, :rotation, :axial_tilt]
    ]
  end

  private

  def normalize_data_types
    %i[period rotation diameter axial_tilt].each do |field|
      value = public_send(field)
      public_send(:"#{field}=", value.presence&.to_f)
    end
  end
end
