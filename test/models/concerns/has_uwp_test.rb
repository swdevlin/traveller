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

  test 'assign_starport_costs rolls berthing cost and sets both fuel costs for class A' do
    planet = TerrestrialPlanet.new
    planet.starport_code = 'A'
    planet.assign_starport_costs(roller: DiceRoller.new(seed: 1))
    assert_includes (1..6).map { |n| n * 1000 }, planet.berthing_cost
    assert_equal 500, planet.refined_fuel_cost
    assert_equal 100, planet.unrefined_fuel_cost
  end

  test 'assign_starport_costs sets unrefined fuel only, no refined, for class C' do
    planet = TerrestrialPlanet.new
    planet.starport_code = 'C'
    planet.assign_starport_costs(roller: DiceRoller.new(seed: 1))
    assert_includes (1..6).map { |n| n * 100 }, planet.berthing_cost
    assert_nil planet.refined_fuel_cost
    assert_equal 100, planet.unrefined_fuel_cost
  end

  test 'assign_starport_costs leaves everything nil for class X' do
    planet = TerrestrialPlanet.new
    planet.starport_code = 'X'
    planet.assign_starport_costs(roller: DiceRoller.new(seed: 1))
    assert_nil planet.berthing_cost
    assert_nil planet.refined_fuel_cost
    assert_nil planet.unrefined_fuel_cost
  end

  test 'assign_starport_costs leaves everything nil for class E' do
    planet = TerrestrialPlanet.new
    planet.starport_code = 'E'
    planet.assign_starport_costs(roller: DiceRoller.new(seed: 1))
    assert_nil planet.berthing_cost
    assert_nil planet.refined_fuel_cost
    assert_nil planet.unrefined_fuel_cost
  end

  test 'assign_starport_costs defaults to class X behaviour when starport_code is unset' do
    planet = TerrestrialPlanet.new
    planet.assign_starport_costs(roller: DiceRoller.new(seed: 1))
    assert_nil planet.berthing_cost
    assert_nil planet.refined_fuel_cost
    assert_nil planet.unrefined_fuel_cost
  end

  test 'culture trait setters round-trip through the population hash' do
    planet = TerrestrialPlanet.new
    planet.population_militancy = 12
    planet.population_cohesion = 7

    assert_equal 12, planet.population_militancy
    assert_equal 7, planet.population_cohesion
    assert_equal 12, planet.population['militancy']
    assert_equal 7, planet.population['cohesion']
  end

  test 'culture trait values are nil when left unset' do
    planet = TerrestrialPlanet.new
    assert_nil planet.population_diversity
  end

  test 'culture trait validation accepts each trait at its own min and max' do
    HasUwp::CULTURE_TRAIT_DATA.each do |trait|
      planet = TerrestrialPlanet.new
      planet.public_send("#{trait[:getter]}=", trait[:min])
      planet.valid?
      assert_empty planet.errors[trait[:getter]], "expected #{trait[:getter]} to allow its min (#{trait[:min]})"

      planet.public_send("#{trait[:getter]}=", trait[:max])
      planet.valid?
      assert_empty planet.errors[trait[:getter]], "expected #{trait[:getter]} to allow its max (#{trait[:max]})"
    end
  end

  test 'culture trait validation rejects values outside a trait\'s own range' do
    HasUwp::CULTURE_TRAIT_DATA.each do |trait|
      planet = TerrestrialPlanet.new
      planet.public_send("#{trait[:getter]}=", trait[:min] - 1)
      planet.valid?
      assert_not_empty planet.errors[trait[:getter]], "expected #{trait[:getter]} to reject below its min (#{trait[:min]})"

      planet.public_send("#{trait[:getter]}=", trait[:max] + 1)
      planet.valid?
      assert_not_empty planet.errors[trait[:getter]], "expected #{trait[:getter]} to reject above its max (#{trait[:max]})"
    end
  end
end
