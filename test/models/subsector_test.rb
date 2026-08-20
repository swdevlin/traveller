require 'test_helper'

class SubsectorTest < ActiveSupport::TestCase
  setup do
    @subsector = subsectors(:subsector_1_1)
  end

  test 'effective_language returns own language when set' do
    campaign = campaigns(:one)
    @subsector.language = 'aslan'
    assert_equal 'aslan', @subsector.effective_language(campaign)
  end

  test 'effective_language falls back to sector language' do
    campaign = campaigns(:one)
    @subsector.sector.language = 'hindi'
    assert_equal 'hindi', @subsector.effective_language(campaign)
  end

  test 'effective_language own language overrides sector language' do
    campaign = campaigns(:one)
    @subsector.sector.language = 'hindi'
    @subsector.language = 'aslan'
    assert_equal 'aslan', @subsector.effective_language(campaign)
  end

  test 'effective_language falls back to campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'nordic'
    assert_nil @subsector.language
    assert_nil @subsector.sector.language
    assert_equal 'nordic', @subsector.effective_language(campaign)
  end

  test 'effective_language returns nil when nothing set' do
    campaign = campaigns(:one)
    assert_nil @subsector.effective_language(campaign)
  end

  test 'apply_deepnight_defaults! inherits sector-level populated when subsector has none' do
    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      unusualChance: 2
      defaultSI: 3
      populated:
        type: full
        allegiance: 3eIm
        minTechLevel: 5
        maxTechLevel: 12
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
    YAML

    @subsector.apply_deepnight_defaults!(data)

    config = YAML.safe_load(@subsector.build)
    assert_equal 'full', config.dig('populated', 'type')
    assert_equal '3eIm', config.dig('populated', 'allegiance')
  end

  test 'apply_deepnight_defaults! does not overwrite subsector populated with sector populated' do
    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      populated:
        type: full
        allegiance: 3eIm
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
          populated:
            type: split-horizontal
            demarcation: 5
            before:
              allegiance: null
            after:
              allegiance: ZhCo
    YAML

    @subsector.apply_deepnight_defaults!(data)

    config = YAML.safe_load(@subsector.build)
    assert_equal 'split-horizontal', config.dig('populated', 'type')
    assert_equal 'ZhCo', config.dig('populated', 'after', 'allegiance')
  end

  test 'apply_deepnight_defaults! creates allegiances from populated allegiance field' do
    Allegiance.where(code: 'GR').delete_all

    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
          populated:
            type: full
            allegiance: GR
            minTechLevel: 5
            maxTechLevel: 12
    YAML

    @subsector.apply_deepnight_defaults!(data)

    assert Allegiance.exists?(code: 'GR')
  end

  test 'apply_deepnight_defaults! creates allegiances from before and after regions' do
    Allegiance.where(code: %w[AA BB]).delete_all

    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
          populated:
            type: split-horizontal
            demarcation: 4
            before:
              allegiance: AA
            after:
              allegiance: BB
    YAML

    @subsector.apply_deepnight_defaults!(data)

    assert Allegiance.exists?(code: 'AA')
    assert Allegiance.exists?(code: 'BB')
  end

  test 'load_t5_defaults! sets build and build_source from uploaded T5 text' do
    subsector = subsectors(:subsector_3_1) # letter C, matching the fixture's hex range
    text = file_fixture('t5_tab_subsector.txt').read

    subsector.load_t5_defaults!(text)

    config = YAML.safe_load(subsector.build)
    assert_equal 'uploaded', subsector.build_source
    assert_equal 32, config['systems'].length
    assert_equal 'Efate', config['systems'].first['name']
  end

  test 'load_t5_defaults! leaves build untouched when the file has no rows' do
    @subsector.build = nil
    @subsector.load_t5_defaults!("Hex\tName\n")

    assert_nil @subsector.build
    assert_nil @subsector.build_source
  end

  test 'load_t5_defaults! ignores rows outside this subsector\'s hexes' do
    text = file_fixture('t5_tab_subsector.txt').read # scoped to subsector C (hexes 1705-2410)

    @subsector.load_t5_defaults!(text) # @subsector is letter A

    assert_nil @subsector.build
    assert_nil @subsector.build_source
  end

  test 'load_t5_defaults! only includes rows matching this subsector\'s letter from a mixed file' do
    text = file_fixture('t5_tab_sector.txt').read # spans all 16 subsectors

    @subsector.load_t5_defaults!(text) # @subsector is letter A

    assert_equal 'uploaded', @subsector.build_source
    assert_match(/Zeycude/, @subsector.build)
    assert_no_match(/Condyole/, @subsector.build)

    plan = YAML.safe_load(@subsector.build)
    assert_equal 24, plan['systems'].size
  end

  test 'apply_deepnight_defaults! skips null allegiances in before and after regions' do
    data = YAML.safe_load(<<~YAML)
      name: Test Sector
      X: 1
      Y: 1
      subsectors:
        - name: Test A
          type: STANDARD
          index: A
          populated:
            type: split-horizontal
            demarcation: 4
            before:
              allegiance: null
            after:
              allegiance: 3eIm
    YAML

    count_before = Allegiance.count

    @subsector.apply_deepnight_defaults!(data)

    assert_equal count_before, Allegiance.count
  end

  test 'systems_scope and worlds_scope only count this subsector, including populated worlds, population and tech level' do
    sector = Sector.create!(x: 9040, y: 9040, skip_subsector_creation: true)
    subsector = Subsector.create!(sector: sector, name: 'Sub A', x: 1, y: 1)
    other_subsector = Subsector.create!(sector: sector, name: 'Sub B', x: 2, y: 1)

    ul, = subsector.universal_coordinates
    parsec = Parsec.create!(sector: sector, x: ul.x, y: ul.y)

    other_ul, = other_subsector.universal_coordinates
    other_parsec = Parsec.create!(sector: sector, x: other_ul.x, y: other_ul.y)

    system = StarSystem.create!(parsec: parsec)
    star = Star.create!(name: 'Star', star_system: system, parsec: parsec, type: 'Star')

    populated = create_world(star: star, name: 'Populated', population_code: 5, tech_level_code: 12)
    populated.population = populated.population.merge('censusPopulation' => 5_000_000)
    populated.save!

    other_system = StarSystem.create!(parsec: other_parsec)
    other_star = Star.create!(name: 'Other Star', star_system: other_system, parsec: other_parsec, type: 'Star')
    create_world(star: other_star, name: 'Other Populated', population_code: 8, tech_level_code: 15)

    assert_equal 1, subsector.number_of_systems
    assert_equal 1, subsector.number_of_populated_worlds
    assert_equal 5_000_000, subsector.total_population
    assert_equal 'Populated', subsector.highest_tech_level_world.name
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
