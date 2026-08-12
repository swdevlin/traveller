require 'test_helper'

class HasUwpTest < ActiveSupport::TestCase
  test 'no_population? is true when population code is absent' do
    planet = TerrestrialPlanet.new
    assert planet.no_population?
  end

  test 'no_population? is true when population code is zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 0
    assert planet.no_population?
  end

  test 'no_population? is false when population code is greater than zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 1
    assert_not planet.no_population?
  end

  test 'no_government? is true when population is zero and government code is absent' do
    planet = TerrestrialPlanet.new
    planet.population_code = 0
    assert planet.no_government?
  end

  test 'no_government? is true when population and government codes are both zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 0
    planet.government_code = 0
    assert planet.no_government?
  end

  test 'no_government? is false when population is zero but government code is greater than zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 0
    planet.government_code = 1
    assert_not planet.no_government?
  end

  test 'no_government? is false when population is greater than zero even if government code is zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 1
    planet.government_code = 0
    assert_not planet.no_government?
  end

  test 'no_law_level? is true when population and law level codes are both zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 0
    planet.law_level_code = 0
    assert planet.no_law_level?
  end

  test 'no_law_level? is false when population is zero but law level code is greater than zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 0
    planet.law_level_code = 1
    assert_not planet.no_law_level?
  end

  test 'no_law_level? is false when population is greater than zero even if law level code is zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 1
    planet.law_level_code = 0
    assert_not planet.no_law_level?
  end

  test 'no_tech_level? is true when population and tech level codes are both zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 0
    planet.tech_level_code = 0
    assert planet.no_tech_level?
  end

  test 'no_tech_level? is false when population is zero but tech level code is greater than zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 0
    planet.tech_level_code = 1
    assert_not planet.no_tech_level?
  end

  test 'no_tech_level? is false when population is greater than zero even if tech level code is zero' do
    planet = TerrestrialPlanet.new
    planet.population_code = 1
    planet.tech_level_code = 0
    assert_not planet.no_tech_level?
  end
end
