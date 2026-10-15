require 'test_helper'

class HydrographicsTest < ActiveSupport::TestCase
  include StellarObjectsHelper
  include ActionView::Helpers::NumberHelper

  def build_planet(hydrographics)
    star_system = StarSystem.create!(name: 'Hydro World', parsec: parsecs(:one))
    star = Star.create!(star_system: star_system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    TerrestrialPlanet.create!(orbiting: star, orbit: 1.0, size_code: '5', atmosphere_code: 6, hydrographics: hydrographics)
  end

  test 'percentage round trips through the data hash' do
    planet = build_planet('code' => 7, 'liquid' => 'Water', 'distribution' => 5, 'percentage' => 71.4)

    assert_in_delta 71.4, planet.reload.hydrographics_percentage
    assert_in_delta 71.4, planet.data.dig('hydrographics', 'percentage')
  end

  test 'editing liquid keeps the percentage' do
    planet = build_planet('code' => 7, 'percentage' => 71.4)
    planet.hydrographics_liquid = 'Ammonia'

    assert_in_delta 71.4, planet.hydrographics_percentage
  end

  test 'changing the code clears the percentage' do
    planet = build_planet('code' => 7, 'percentage' => 71.4)
    planet.hydrographics_code = 3

    assert_nil planet.hydrographics_percentage
  end

  test 'resubmitting the same code keeps the percentage' do
    planet = build_planet('code' => 7, 'percentage' => 71.4)
    planet.hydrographics_code = '7'

    assert_in_delta 71.4, planet.hydrographics_percentage
  end

  test 'hydrographics_coverage prefers the percentage over the range' do
    assert_equal '71.4%', hydrographics_coverage(Hydrographics.new(code: 7, percentage: 71.4))
    assert_equal '70%', hydrographics_coverage(Hydrographics.new(code: 7, percentage: 70.0))
    assert_equal '66%–75%', hydrographics_coverage(Hydrographics.new(code: 7))
  end

  test 'json emits percentage, null when absent' do
    [[build_planet('code' => 7, 'percentage' => 71.4), 71.4], [build_planet('code' => 7), nil]].each do |planet, expected|
      json = JSON.parse(ApplicationController.render(
        partial: 'stellar_objects/uwp_details', formats: [:json],
        locals: { stellar_object: planet, render_context: {} }
      ))
      assert json['hydrographics'].key?('percentage')
      expected.nil? ? assert_nil(json.dig('hydrographics', 'percentage')) : assert_in_delta(expected, json.dig('hydrographics', 'percentage'))
    end
  end
end
