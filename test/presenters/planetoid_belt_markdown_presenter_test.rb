require 'test_helper'

class PlanetoidBeltMarkdownPresenterTest < ActiveSupport::TestCase
  def setup
    parsec = Parsec.create!(sector: sectors(:one), x: 33, y: 27)
    @system = StarSystem.create!(parsec: parsec, meta: {})
    @primary = Star.new(star_system: @system, orbit: 0, orbit_sequence: 'A')
    @primary.stellar_type = 'G'
    @primary.stellar_subtype = 5
    @primary.stellar_class = 'V'
    @primary.save!
  end

  test 'renders explicit periapsis/apoapsis temperature from the generator' do
    belt = PlanetoidBelt.create!(orbiting: @primary, star_system: @system, orbit: 2.5)
    belt.data = belt.data.merge('temperature' => 280.0, 'periapsis_temperature' => 310.0, 'apoapsis_temperature' => 260.0)
    belt.save!

    markdown = PlanetoidBeltMarkdownPresenter.new(belt).render

    assert_includes markdown, 'Temperature | 7°C'
    assert_includes markdown, 'Periapsis Temperature | 37°C'
    assert_includes markdown, 'Apoapsis Temperature | -13°C'
  end

  test 'renders current temperature derived from the real orbital position' do
    belt = PlanetoidBelt.create!(orbiting: @primary, star_system: @system, orbit: 2.5)
    belt.data = belt.data.merge('temperature' => 280.0)
    belt.orbit_x = 0.9 * belt.au.to_f * StellarConstants::AU_TO_KM
    belt.orbit_y = 0.0
    belt.save!

    markdown = PlanetoidBeltMarkdownPresenter.new(belt).render

    assert_includes markdown, "Current Temperature | #{(280.0 / Math.sqrt(0.9) - StellarConstants::KELVIN_TO_CELSIUS_OFFSET).round}°C"
  end

  test 'omits temperature rows when the belt has no temperature data' do
    belt = PlanetoidBelt.create!(orbiting: @primary, star_system: @system, orbit: 2.5)

    markdown = PlanetoidBeltMarkdownPresenter.new(belt).render

    assert_not_includes markdown, 'Temperature'
  end
end
