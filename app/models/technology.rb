class Technology
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :code, :integer
  attribute :energy, :integer
  attribute :electronics, :integer
  attribute :manufacturing, :integer
  attribute :medical, :integer
  attribute :environmental, :integer
  attribute :land, :integer
  attribute :sea, :integer
  attribute :air, :integer
  attribute :space, :integer
  attribute :personal_military, :integer
  attribute :heavy_military, :integer

  def self.from_hash(hash)
    return nil if hash.blank?
    new(
      code: hash['code'],
      energy: hash['energy'],
      electronics: hash['electronics'],
      manufacturing: hash['manufacturing'],
      medical: hash['medical'],
      environmental: hash['environmental'],
      land: hash['land'],
      sea: hash['sea'],
      air: hash['air'],
      space: hash['space'],
      personal_military: hash['personal_military'],
      heavy_military: hash['heavy_military']
    )
  end

  def to_h
    {
      'code' => code,
      'energy' => energy,
      'electronics' => electronics,
      'manufacturing' => manufacturing,
      'medical' => medical,
      'environmental' => environmental,
      'land' => land,
      'sea' => sea,
      'air' => air,
      'space' => space,
      'personal_military' => personal_military,
      'heavy_military' => heavy_military
    }
  end
end
