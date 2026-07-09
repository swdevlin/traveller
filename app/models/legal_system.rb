class LegalSystem
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :code, :integer
  attribute :private_law, :integer
  attribute :criminal_law, :integer
  attribute :economic_law, :integer
  attribute :personal_rights, :integer
  attribute :weapons_and_armour, :integer
  attribute :uniformity, :string
  attribute :judicial_system, :string
  attribute :death_penalty, :boolean
  attribute :presumed_innocence, :boolean
  attribute :econometric_infractions_administrative, :boolean

  def self.from_hash(hash)
    return nil if hash.blank?
    code = hash['code']
    return nil if code.nil?
    new(
      code: code,
      private_law: hash['privateLaw'],
      criminal_law: hash['criminalLaw'],
      economic_law: hash['economicLaw'],
      personal_rights: hash['personalRights'],
      weapons_and_armour: hash['weaponsAndArmour'],
      uniformity: hash['uniformity'],
      judicial_system: hash['judicialSystem'],
      death_penalty: hash['deathPenalty'],
      presumed_innocence: hash['presumedInnocence'],
      econometric_infractions_administrative: hash['econometricInfractionsAdministrative']
    )
  end

  def to_h
    h = { 'code' => code }
    h['privateLaw'] = private_law unless private_law.nil?
    h['criminalLaw'] = criminal_law unless criminal_law.nil?
    h['economicLaw'] = economic_law unless economic_law.nil?
    h['personalRights'] = personal_rights unless personal_rights.nil?
    h['weaponsAndArmour'] = weapons_and_armour unless weapons_and_armour.nil?
    h['uniformity'] = uniformity if uniformity.present?
    h['judicialSystem'] = judicial_system if judicial_system.present?
    h['deathPenalty'] = death_penalty unless death_penalty.nil?
    h['presumedInnocence'] = presumed_innocence unless presumed_innocence.nil?
    h['econometricInfractionsAdministrative'] = econometric_infractions_administrative unless econometric_infractions_administrative.nil?
    h
  end
end
