class Comet < StellarObject
  store_accessor :data, :comet_type
  DESCRIPTIONS = {
    'tiny'      => 'Tiny, ice-bearing suitable for one refuelling only',
    'medium'    => 'Ice-bearing suitable for multiple refuellings',
    'large'     => 'Large',
    'inhabited' => 'Inhabited'
  }.freeze

  validate :comet_type_is_valid

  def self.allowed_data_keys
    %i[comet_type]
  end

  def self.permitted_params
    [:name, :notes, data: [:comet_type]]
  end

  def comet_type_description
    DESCRIPTIONS[comet_type] || comet_type&.humanize
  end

  private

  def comet_type_is_valid
    return if comet_type.blank?

    unless DESCRIPTIONS.key?(comet_type)
      errors.add(:data, 'comet type is invalid')
    end
  end
end
