class SeedDefaultTravelZones < ActiveRecord::Migration[8.1]
  DEFAULTS = [
    { code: 'A', name: 'Amber', colour: '#eab308', protected: true },
    { code: 'R', name: 'Red',   colour: '#dc2626', protected: true }
  ].freeze

  def up
    DEFAULTS.each do |attrs|
      next if TravelZone.exists?(code: attrs[:code])

      TravelZone.create!(attrs)
    end
  end

  def down
    TravelZone.where(code: %w[A R]).destroy_all
  end
end
