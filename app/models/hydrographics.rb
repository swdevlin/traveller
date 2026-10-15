class Hydrographics
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :code, :integer
  attribute :liquid, :string
  attribute :distribution, :integer
  attribute :percentage, :float

  def self.from_hash(hash)
    return nil if hash.blank?
    new(
      code: hash['code'],
      liquid: hash['liquid'],
      distribution: hash['distribution'],
      percentage: hash['percentage']
    )
  end

  def to_h
    {
      'code' => code,
      'liquid' => liquid,
      'distribution' => distribution,
      'percentage' => percentage
    }
  end
end
