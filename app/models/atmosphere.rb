class Atmosphere
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :code, :integer
  attribute :composition, :string
  attribute :density, :string
  attribute :hazard_code, :string
  attribute :bar, :float
  attribute :subtype, :string
  attribute :irritant, :boolean
  attribute :characteristic, :string
  attribute :taint_code, :string
  attribute :taint_severity, :integer
  attribute :taint_persistence, :integer
  attribute :taint_subtype, :string

  attr_accessor :gases

  TAINT_SUBTYPES = {
    'L' => 'Low Oxygen', 'R' => 'Radioactivity', 'B' => 'Biological',
    'G' => 'Gas Mix', 'P' => 'Particulates', 'S' => 'Sulphur Compounds', 'H' => 'High Oxygen'
  }.freeze

  KNOWN_KEYS = %w[code composition density hazardCode bar subtype irritant characteristic taint gases].freeze

  def self.from_hash(hash)
    return nil if hash.blank?
    taint = hash['taint'] || {}
    atm = new(
      code: hash['code'],
      composition: hash['composition'],
      density: hash['density'],
      hazard_code: hash['hazardCode'],
      bar: hash['bar'],
      subtype: hash['subtype'],
      irritant: hash['irritant'],
      characteristic: hash['characteristic'],
      taint_code: taint['code'],
      taint_severity: taint['severity'],
      taint_persistence: taint['persistence'],
      taint_subtype: taint['subtype']
    )
    atm.gases = hash['gases']
    atm.instance_variable_set(:@extra, hash.except(*KNOWN_KEYS))
    atm
  end

  def to_h
    (@extra || {}).merge(
      'code' => code,
      'composition' => composition,
      'density' => density,
      'hazardCode' => hazard_code,
      'bar' => bar,
      'subtype' => subtype,
      'irritant' => irritant,
      'characteristic' => characteristic,
      'gases' => gases,
      'taint' => {
        'code' => taint_code || '',
        'severity' => taint_severity || 0,
        'persistence' => taint_persistence || 0,
        'subtype' => taint_subtype || ''
      }
    )
  end

  def tainted?
    taint_code.present?
  end
end
