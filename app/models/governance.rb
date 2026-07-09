class Governance
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :code, :integer
  attribute :authority, :string
  attribute :centralisation, :string
  attribute :judicial, :string
  attribute :executive, :string
  attribute :legislative, :string

  def self.from_hash(hash)
    return nil if hash.blank?
    code = hash['code']
    return nil if code.nil?
    new(
      code: code,
      authority: hash['authority'],
      centralisation: hash['centralisation'],
      judicial: hash.dig('structure', 'judicial'),
      executive: hash.dig('structure', 'executive'),
      legislative: hash.dig('structure', 'legislative')
    )
  end

  def to_h
    h = { 'code' => code }
    h['authority'] = authority if authority.present?
    h['centralisation'] = centralisation if centralisation.present?
    structure = {}
    structure['judicial'] = judicial if judicial.present?
    structure['executive'] = executive if executive.present?
    structure['legislative'] = legislative if legislative.present?
    h['structure'] = structure if structure.present?
    h
  end
end
