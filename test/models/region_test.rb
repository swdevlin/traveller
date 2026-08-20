require 'test_helper'

class RegionTest < ActiveSupport::TestCase
  test 'statistics and allegiance breakdown count worlds in both fill and border parsecs' do
    allegiance_a = Allegiance.create!(code: 'rg-a', name: 'Allegiance A')
    allegiance_b = Allegiance.create!(code: 'rg-b', name: 'Allegiance B')

    sector = Sector.create!(x: 9002, y: 9002, skip_subsector_creation: true)
    fill_parsec = Parsec.create!(x: 9002, y: 9002, sector: sector)
    border_parsec = Parsec.create!(x: 9003, y: 9002, sector: sector)
    outside_parsec = Parsec.create!(x: 9004, y: 9002, sector: sector)

    region = Region.create!(name: 'Test Region', source: 'manual')
    RegionParsec.create!(region: region, parsec: fill_parsec, kind: 'fill')
    RegionParsec.create!(region: region, parsec: border_parsec, kind: 'border')

    fill_system = StarSystem.create!(parsec: fill_parsec)
    fill_star = Star.create!(name: 'Fill Star', star_system: fill_system, parsec: fill_parsec, type: 'Star')
    create_world(star: fill_star, allegiance: allegiance_a, name: 'A Populated', population_code: 5)
    create_world(star: fill_star, allegiance: allegiance_a, name: 'A Uninhabited', population_code: 0)
    create_world(star: fill_star, allegiance: allegiance_b, name: 'B Populated', population_code: 3)

    border_system = StarSystem.create!(parsec: border_parsec)
    border_star = Star.create!(name: 'Border Star', star_system: border_system, parsec: border_parsec, type: 'Star')
    create_world(star: border_star, allegiance: allegiance_a, name: 'Border Populated', population_code: 6)

    outside_system = StarSystem.create!(parsec: outside_parsec)
    outside_star = Star.create!(name: 'Outside Star', star_system: outside_system, parsec: outside_parsec, type: 'Star')
    create_world(star: outside_star, allegiance: allegiance_a, name: 'Outside Populated', population_code: 6)

    assert_equal 2, region.number_of_systems
    assert_equal 3, region.number_of_populated_worlds

    counts = region.allegiance_world_counts
    assert_equal({ total: 3, populated: 2 }, counts[allegiance_a.id])
    assert_equal({ total: 1, populated: 1 }, counts[allegiance_b.id])
  end

  test 'has no systems or worlds when it has no fill parsecs' do
    region = Region.create!(name: 'Borderless Region', source: 'manual')

    assert_equal 0, region.number_of_systems
    assert_equal 0, region.number_of_populated_worlds
    assert_empty region.allegiance_world_counts
  end

  private

  def create_world(star:, allegiance:, name:, population_code:)
    planet = TerrestrialPlanet.new(name: name, orbiting: star, allegiance: allegiance, orbit: 1, size_code: '5')
    planet.atmosphere_code = 6
    planet.hydrographics_code = 5
    planet.population_code = population_code
    planet.save!
    planet
  end
end
