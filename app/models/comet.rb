class Comet < StellarObject
  TYPES = %w[inhabited tiny medium large].freeze

  validate :comet_type_is_valid

  def self.allowed_data_keys
    %i[comet_type]
  end

  def comet_type
    data&.dig("comet_type")
  end

  private
  def comet_type_is_valid
    return if comet_type.blank?

    errors.add(:data, "comet type is invalid") unless TYPES.include?(comet_type)
  end
end
