require 'test_helper'

class TerrestrialPlanetTest < ActiveSupport::TestCase
  test 'assign_data_from_generator stores periapsis/apoapsis temperature from the payload' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator({ 'meanTemperature' => 280.0, 'periapsisTemperature' => 310.0, 'apoapsisTemperature' => 260.0 })

    assert_equal 280.0, planet.temperature
    assert_equal 310.0, planet.periapsis_temperature
    assert_equal 260.0, planet.apoapsis_temperature
  end

  test 'assign_data_from_generator stores ice caps and latitude temperatures' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator({
      'iceCaps' => { 'liquid' => 'Water', 'meltingPointK' => 273, 'edgeTemperatureK' => 263, 'edgeLatitude' => 54, 'coverage' => 0.191, 'note' => nil },
      'latitudeTemperatures' => [{ 'latitude' => 0, 'temperature' => 281.6 }, { 'latitude' => 90, 'temperature' => 237.9 }]
    })

    assert_equal 273, planet.ice_caps['melting_point_k']
    assert_equal 54, planet.ice_caps['edge_latitude']
    assert_equal 2, planet.latitude_temperatures.size
    assert_equal 237.9, planet.latitude_temperatures.last['temperature']
  end

  test 'ice caps and latitude temperatures are nil when the payload omits them' do
    planet = TerrestrialPlanet.new
    planet.assign_data_from_generator({})

    assert_nil planet.ice_caps
    assert_nil planet.latitude_temperatures
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
