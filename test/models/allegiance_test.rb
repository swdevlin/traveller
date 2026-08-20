require 'test_helper'

class AllegianceTest < ActiveSupport::TestCase
  test 'has no systems or worlds when nothing is assigned to it' do
    allegiance = Allegiance.create!(code: 'stat-empty', name: 'Empty Allegiance')

    assert_equal 0, allegiance.number_of_systems
    assert_equal 0, allegiance.number_of_populated_worlds
    assert_equal 0, allegiance.total_population
    assert_equal 0, allegiance.worlds_with_known_census_count
    assert_nil allegiance.highest_population_world
    assert_nil allegiance.highest_tech_level_world
    assert_empty allegiance.tech_level_histogram
    assert_empty allegiance.government_histogram
    assert_empty allegiance.law_level_histogram
  end

  test 'aggregates systems, population, and tech level worlds' do
    allegiance = Allegiance.create!(code: 'stat-full', name: 'Full Allegiance')
    other_allegiance = Allegiance.create!(code: 'stat-other', name: 'Other Allegiance')

    sector = Sector.create!(x: 9001, y: 9001, skip_subsector_creation: true)
    parsec = Parsec.create!(x: 9001, y: 9001, sector: sector)
    star_system = StarSystem.create!(parsec: parsec, allegiance: allegiance)
    star = Star.create!(name: 'Primary', star_system: star_system, parsec: parsec, type: 'Star')

    other_parsec = Parsec.create!(x: 9001, y: 9002, sector: sector)
    other_star_system = StarSystem.create!(parsec: other_parsec, allegiance: other_allegiance)
    other_star = Star.create!(name: 'Other Primary', star_system: other_star_system, parsec: other_parsec, type: 'Star')

    high_pop = create_world(star: star, allegiance: nil, name: 'Highpop',
                             population_code: 9, census_population: 4_000_000_000, tech_level_code: 8)
    create_world(star: star, allegiance: nil, name: 'Lowpop',
                 population_code: 3, tech_level_code: 2)
    create_world(star: star, allegiance: nil, name: 'Tied Low A',
                 population_code: 4, tech_level_code: 1)
    create_world(star: star, allegiance: nil, name: 'Tied Low B',
                 population_code: 5, tech_level_code: 1)
    create_world(star: other_star, allegiance: nil, name: 'Not Ours',
                 population_code: 9, tech_level_code: 15)
    create_world(star: star, allegiance: nil, name: 'Uninhabited', population_code: 0)

    assert_equal 1, allegiance.number_of_systems
    assert_equal 4, allegiance.number_of_populated_worlds
    assert_equal 4_000_000_000, allegiance.total_population
    assert_equal 1, allegiance.worlds_with_known_census_count

    assert_equal high_pop, allegiance.highest_population_world
    assert_equal 8, allegiance.highest_tech_level_world.tech_level_code

    assert_equal({ 1 => 2, 2 => 1, 8 => 1 }, allegiance.tech_level_histogram)
  end

  test 'finds worlds via star system allegiance when stellar objects have no allegiance_id of their own' do
    allegiance = Allegiance.create!(code: 'stat-via-system', name: 'Via System Allegiance')

    sector = Sector.create!(x: 9002, y: 9002, skip_subsector_creation: true)
    parsec = Parsec.create!(x: 9002, y: 9002, sector: sector)
    star_system = StarSystem.create!(parsec: parsec, allegiance: allegiance)
    star = Star.create!(name: 'Primary', star_system: star_system, parsec: parsec, type: 'Star')

    create_world(star: star, allegiance: nil, name: 'Unlinked Pop',
                 population_code: 9, tech_level_code: 8)

    assert_equal 1, allegiance.number_of_populated_worlds
    assert_equal({ 8 => 1 }, allegiance.tech_level_histogram)
  end

  private

  def create_world(star:, allegiance:, name:, population_code:, tech_level_code: nil, census_population: nil)
    planet = TerrestrialPlanet.new(name: name, orbiting: star, allegiance: allegiance, orbit: 1, size_code: '5')
    planet.atmosphere_code = 6
    planet.hydrographics_code = 5
    planet.population_code = population_code
    planet.tech_level_code = tech_level_code if tech_level_code
    planet.population = planet.population.merge('censusPopulation' => census_population) if census_population
    planet.save!
    planet
  end
end
