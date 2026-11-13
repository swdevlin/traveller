require 'test_helper'

class SectorStatisticsTest < ActiveSupport::TestCase
  setup do
    @sector = Sector.create!(name: 'Stats Sector', x: 9050, y: 9050, skip_subsector_creation: true)
    @sub_a = Subsector.create!(sector: @sector, name: 'A', x: 1, y: 1)
    @sub_b = Subsector.create!(sector: @sector, name: 'B', x: 2, y: 3)
    @empty = Subsector.create!(sector: @sector, name: 'Empty', x: 4, y: 4)
    @allegiance = Allegiance.first || Allegiance.create!(code: 'Zz', name: 'Test')

    @world_a = build_world(@sub_a, offset: 0, population_code: 5, census: 5_000_000, tech_level: 12, allegiance: @allegiance)
    @world_a2 = build_world(@sub_a, offset: 1, population_code: 3, census: nil, tech_level: 9)
    @world_b = build_world(@sub_b, offset: 0, population_code: 8, census: 800_000_000, tech_level: 15)
    @unpopulated_system = StarSystem.create!(parsec: Parsec.create!(sector: @sector, x: @sub_b.universal_coordinates.first.x + 1, y: @sub_b.universal_coordinates.first.y))

    @stats = SectorStatistics.new(@sector)
  end

  test 'subsector summaries match the per-subsector queries' do
    [@sub_a, @sub_b, @empty].each do |subsector|
      summary = @stats.summary_for(subsector)
      assert_equal subsector.number_of_star_systems, summary.number_of_star_systems, subsector.name
      assert_equal subsector.number_of_populated_star_systems, summary.number_of_populated_star_systems, subsector.name
      assert_equal subsector.worlds_with_known_census_count, summary.worlds_with_known_census_count, subsector.name
      assert_equal subsector.total_population.to_i, summary.total_population.to_i, subsector.name
      assert_equal [subsector.highest_tech_level_world&.tech_level_code], [summary.highest_tech_level_code], subsector.name
      assert_equal subsector.allegiances.order(:code).to_a, summary.allegiances, subsector.name
    end
  end

  test 'sector totals match the sector queries' do
    assert_equal @sector.number_of_populated_worlds, @stats.number_of_populated_worlds
    assert_equal @sector.worlds_with_known_census_count, @stats.worlds_with_known_census_count
    assert_equal @sector.total_population.to_i, @stats.total_population.to_i
    assert_equal [@sector.highest_tech_level_world&.tech_level_code], [@stats.highest_tech_level_code]
    assert_equal @sector.highest_population_world, @stats.highest_population_world
    assert_equal @sector.get_allegiances.count, @stats.allegiance_count
    assert_equal @sector.systems_scope.count, @stats.number_of_star_systems
  end

  test 'the highest population world is the most populous' do
    assert_equal @world_b, @stats.highest_population_world
  end

  test 'a subsector with no systems has empty figures' do
    summary = @stats.summary_for(@empty)
    assert_equal 0, summary.number_of_star_systems
    assert_nil summary.highest_tech_level_code
    assert_empty summary.allegiances
  end

  test 'issues a fixed number of queries regardless of subsector count' do
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == 'SCHEMA' || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { SectorStatistics.new(@sector) }
    assert_operator count, :<=, 4
  end

  test 'totals are cached until something in the sector changes' do
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    sector = Sector.find(@sector.id)

    assert_equal 3, SectorStatistics.new(sector).number_of_populated_worlds

    count = 0
    counter = ->(*, payload) { count += 1 if payload[:sql].include?('stellar_objects') && !payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
      SectorStatistics.new(Sector.find(@sector.id))
    end
    assert_equal 0, count, 'second load should come from the cache'

    @world_b.update!(population_code: 0)
    assert_equal 2, SectorStatistics.new(Sector.find(@sector.id)).number_of_populated_worlds
  ensure
    Rails.cache = original
  end

  private

  def build_world(subsector, offset:, population_code:, census:, tech_level:, allegiance: nil)
    ul, = subsector.universal_coordinates
    parsec = Parsec.create!(sector: @sector, x: ul.x + offset, y: ul.y)
    system = StarSystem.create!(parsec: parsec, allegiance: allegiance)
    star = Star.create!(name: 'Star', star_system: system, parsec: parsec, type: 'Star')
    planet = TerrestrialPlanet.new(name: "World #{subsector.name}#{offset}", orbiting: star, orbit: 1, size_code: '5')
    planet.atmosphere_code = 6
    planet.hydrographics_code = 5
    planet.population_code = population_code
    planet.tech_level_code = tech_level
    planet.save!
    planet.population = planet.population.merge('censusPopulation' => census) if census
    planet.save!
    planet
  end
end
