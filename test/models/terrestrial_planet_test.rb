require 'test_helper'

class TerrestrialPlanetTest < ActiveSupport::TestCase
  test 'assign_data_from_generator stores periapsis/apoapsis temperature from the payload' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator({ 'meanTemperature' => 280.0, 'periapsisTemperature' => 310.0, 'apoapsisTemperature' => 260.0 })

    assert_equal 280.0, planet.temperature
    assert_equal 310.0, planet.periapsis_temperature
    assert_equal 260.0, planet.apoapsis_temperature
  end

  test 'periapsis/apoapsis temperature fall back to an estimate when the payload omits them' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator({ 'meanTemperature' => 280.0, 'eccentricity' => 0.2 })

    assert_in_delta 280.0 / Math.sqrt(0.8), planet.periapsis_temperature, 0.001
    assert_in_delta 280.0 / Math.sqrt(1.2), planet.apoapsis_temperature, 0.001
  end

  test 'periapsis/apoapsis temperature are nil when the body has no mean temperature at all' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator({ 'eccentricity' => 0.2 })

    assert_nil planet.periapsis_temperature
    assert_nil planet.apoapsis_temperature
  end

  test 'current temperature is derived from the real orbital position' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator(
      {
        'meanTemperature' => 280.0,
        'au' => 1.0,
        'orbitPosition' => { 'x' => 0.9 * StellarConstants::AU_TO_KM, 'y' => 0.0 }
      }
    )

    assert_in_delta 280.0 / Math.sqrt(0.9), planet.current_temperature, 0.001
  end

  test 'current temperature falls back to the mean temperature without a known orbital position' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator({ 'meanTemperature' => 280.0, 'au' => 1.0, 'eccentricity' => 0.2 })

    assert_equal 280.0, planet.current_temperature
  end

  test 'current temperature is nil when the body has no mean temperature at all' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator({ 'au' => 1.0, 'eccentricity' => 0.2 })

    assert_nil planet.current_temperature
  end
end
