require 'test_helper'

class SectorTest < ActiveSupport::TestCase
  test 'effective_language returns own language when set' do
    campaign = campaigns(:one)
    sector = Sector.new(x: 99, y: 99, language: 'aslan')
    assert_equal 'aslan', sector.effective_language(campaign)
  end

  test 'effective_language falls back to campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'nordic'
    sector = Sector.new(x: 99, y: 99)
    assert_equal 'nordic', sector.effective_language(campaign)
  end

  test 'effective_language own language overrides campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'nordic'
    sector = Sector.new(x: 99, y: 99, language: 'aslan')
    assert_equal 'aslan', sector.effective_language(campaign)
  end

  test 'effective_language returns nil when nothing set' do
    campaign = campaigns(:one)
    assert_nil Sector.new(x: 99, y: 99).effective_language(campaign)
  end

  test 'validates language must be a recognised language' do
    sector = sectors(:one)
    sector.language = 'klingon'
    assert_not sector.valid?
    assert sector.errors[:language].any?
  end

  test 'validates language allows blank' do
    sector = sectors(:one)
    sector.language = ''
    assert sector.valid?
  end

  test 'default_build_source is traveller_map when the sector was imported from Traveller Map' do
    sector = Sector.new(source: 'traveller_map', x: 1, y: 1)
    assert_equal 'traveller_map', sector.default_build_source
  end

  test 'default_build_source is deepnight when bundled data exists for the coordinates' do
    sector = Sector.new(x: -10, y: -1)
    assert_equal 'deepnight', sector.default_build_source
  end

  test 'default_build_source is nil when neither Traveller Map nor Deepnight data applies' do
    sector = Sector.new(x: 1, y: 1)
    assert_nil sector.default_build_source
  end

  def stub_metadata(x, y, status: 200, body: nil)
    stub_request(:get, "https://travellermap.com/api/metadata?sx=#{x}&sy=#{-y}")
      .to_return(status: status, body: body || { 'Subsectors' => [] }.to_json)
  end

  test 'traveller_map sector is valid and saves when metadata fetch succeeds' do
    stub_metadata(50, 50)
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert sector.save
  end

  test 'traveller_map sector is invalid when metadata fetch returns a non-2xx status' do
    stub_metadata(50, 50, status: 500, body: 'boom')
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert_not sector.save
    assert sector.errors[:base].any?
  end

  test 'traveller_map sector is invalid on a network timeout' do
    stub_request(:get, %r{travellermap\.com/api/metadata}).to_timeout
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert_not sector.save
    assert sector.errors[:base].any?
  end

  test 'traveller_map sector is invalid when the response body is not valid JSON' do
    stub_metadata(50, 50, body: 'not json')
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert_not sector.save
    assert sector.errors[:base].any?
  end

  test 'traveller_map sector is invalid when the response is an empty JSON object' do
    stub_metadata(50, 50, body: '{}')
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert_not sector.save
    assert sector.errors[:base].any?
  end

  test 'requests the correct query string sign for x and y' do
    stub = stub_metadata(50, 50)
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    sector.save!

    assert_requested stub
  end

  test 'creates jump routes from metadata at sector-creation time for already-existing neighbours' do
    neighbour = Sector.create!(name: 'Neighbour', x: 50, y: 51, abbreviation: 'NB', skip_subsector_creation: true)
    ul = neighbour.upper_left
    parsec_a = Parsec.create!(sector: neighbour, x: ul.x, y: ul.y, q: ul.x, r: -ul.y - ((ul.x - (ul.x & 1)) / 2), s: 0)
    parsec_a.update!(s: -parsec_a.q - parsec_a.r)
    parsec_b = Parsec.create!(sector: neighbour, x: ul.x + 1, y: ul.y - 1, q: ul.x + 1, r: -(ul.y - 1) - (((ul.x + 1) - ((ul.x + 1) & 1)) / 2), s: 0)
    parsec_b.update!(s: -parsec_b.q - parsec_b.r)
    system_a = StarSystem.create!(name: 'A', parsec: parsec_a)
    system_b = StarSystem.create!(name: 'B', parsec: parsec_b)

    stub_metadata(50, 50, body: {
      'Subsectors' => [],
      'Routes' => [{ 'Start' => '0101', 'End' => '0202', 'StartOffsetY' => -1, 'EndOffsetY' => -1 }]
    }.to_json)

    Sector.create!(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    jump_route = JumpRoute.find_by(travellermap_allegiance_code: 'Im')
    assert jump_route
    low_id, high_id = [system_a.id, system_b.id].sort
    assert JumpRouteLink.exists?(from_star_system_id: low_id, to_star_system_id: high_id)
  end

  test 'systems_scope and worlds_scope only count this sector, including populated worlds, population and tech level' do
    sector = Sector.create!(x: 9020, y: 9020, skip_subsector_creation: true)
    other_sector = Sector.create!(x: 9021, y: 9020, skip_subsector_creation: true)

    parsec = Parsec.create!(sector: sector, x: sector.x * 32, y: sector.y * 40)
    other_parsec = Parsec.create!(sector: other_sector, x: other_sector.x * 32, y: other_sector.y * 40)

    system = StarSystem.create!(parsec: parsec)
    star = Star.create!(name: 'Star', star_system: system, parsec: parsec, type: 'Star')

    populated = create_world(star: star, name: 'Populated', population_code: 5, tech_level_code: 12)
    populated.population = populated.population.merge('censusPopulation' => 5_000_000)
    populated.save!

    create_world(star: star, name: 'Uninhabited', population_code: 0, tech_level_code: nil)

    GasGiant.create!(name: 'Rogue', parsec: parsec)

    other_system = StarSystem.create!(parsec: other_parsec)
    other_star = Star.create!(name: 'Other Star', star_system: other_system, parsec: other_parsec, type: 'Star')
    create_world(star: other_star, name: 'Other Populated', population_code: 8, tech_level_code: 15)

    assert_equal 1, sector.number_of_systems
    assert_equal 1, sector.number_of_populated_worlds
    assert_equal 5_000_000, sector.total_population
    assert_equal 'Populated', sector.highest_tech_level_world.name
  end

  private

  def create_world(star:, name:, population_code:, tech_level_code: nil)
    planet = TerrestrialPlanet.new(name: name, orbiting: star, orbit: 1, size_code: '5')
    planet.atmosphere_code = 6
    planet.hydrographics_code = 5
    planet.population_code = population_code
    planet.tech_level_code = tech_level_code
    planet.save!
    planet
  end
end
