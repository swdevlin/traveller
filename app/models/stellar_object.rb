class StellarObject < ApplicationRecord
  belongs_to :Parsec, optional: true
  belongs_to :SolarSystem, optional: true
  belongs_to :StellarObject, optional: true

  validate :parsec_or_solar_system_required

  private

  def parsec_or_solar_system_required
    return if parsec_id.present? || solar_system_id.present?
    errors.add(:base, "stellar object must belong to a parsec or solar system")
  end

end
