# frozen_string_literal: true

require 'test_helper'

class SubsectorBuildConfigExporterTest < ActiveSupport::TestCase
  # Sector one is at x=1, y=1 → upper_left = Coordinate(32, 40).
  # subsector_1_2 (x=1, y=2) covers x:32..39, y:21..30.
  # Fixture parsec :one is at (32, 40) — outside this range — so no fixture star
  # systems bleed in. Rails transactional tests roll back all DB changes automatically.

  def setup
    @subsector = subsectors(:subsector_1_2)
    # Position (2, 5) in the subsector → universal x=33, y=26
    @parsec    = Parsec.create!(sector: sectors(:one), x: 33, y: 26)
  end

  # ── top-level config ─────────────────────────────────────────────────────────

  test 'preserves type and language from existing build' do
    @subsector.build = "---\ntype: DENSE\nlanguage: english\n"
    config = SubsectorBuildConfigExporter.new(@subsector).export
    assert_equal 'DENSE',   config['type']
    assert_equal 'english', config['language']
  end

  test 'defaults to STANDARD when no existing build' do
    @subsector.build = nil
    config = SubsectorBuildConfigExporter.new(@subsector).export
    assert_equal 'STANDARD', config['type']
  end

  test 'replaces systems from existing build with DB contents' do
    @subsector.build = "---\ntype: MODERATE\nunusualChance: 5\n"
    system = StarSystem.create!(parsec: @parsec, meta: {})
    _primary = build_primary_star(system)

    config = SubsectorBuildConfigExporter.new(@subsector).export

    assert_equal 'MODERATE', config['type']
    assert_equal 5, config['unusualChance']
    assert_equal 1, config['systems'].size
    assert_equal 2, config['systems'].first['x']
    assert_equal 5, config['systems'].first['y']
  end

  # ── system attributes ────────────────────────────────────────────────────────

  test 'exports subsector-relative coordinates' do
    system = StarSystem.create!(parsec: @parsec, meta: {})
    _primary = build_primary_star(system)

    config = SubsectorBuildConfigExporter.new(@subsector).export

    entry = config['systems'].first
    assert_equal 2, entry['x']
    assert_equal 5, entry['y']
  end

  test 'exports system name, allegiance, and survey index' do
    allegiance = Allegiance.find_or_create_by!(code: 'ImTs') { |a| a.name = 'Imperium' }
    system     = StarSystem.create!(
      parsec: @parsec, meta: {}, name: 'Kolan', survey_index: 3, allegiance: allegiance
    )
    _primary = build_primary_star(system)

    entry = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first

    assert_equal 'Kolan', entry['name']
    assert_equal 3,       entry['surveyIndex']
    assert_equal 'ImTs',  entry['allegiance']
  end

  # ── star tree ────────────────────────────────────────────────────────────────

  test 'exports primary star type and class' do
    system   = StarSystem.create!(parsec: @parsec, meta: {})
    _primary = build_primary_star(system, type: 'G', subtype: 5, klass: 'V')

    primary = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']

    assert_equal 'G5', primary['type']
    assert_equal 'V',  primary['class']
  end

  test 'exports special spectral type without subtype or class' do
    system   = StarSystem.create!(parsec: @parsec, meta: {})
    _primary = build_primary_star(system, type: 'BD', subtype: nil, klass: nil)

    primary = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']

    assert_equal 'BD', primary['type']
    assert_nil primary['class']
  end

  test 'exports brown dwarf spectral type with subtype but no class' do
    system   = StarSystem.create!(parsec: @parsec, meta: {})
    _primary = build_primary_star(system, type: 'L', subtype: 5, klass: nil)

    primary = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']

    assert_equal 'L5', primary['type']
    assert_nil primary['class']
  end

  test 'exports near secondary star' do
    system    = StarSystem.create!(parsec: @parsec, meta: {})
    primary   = build_primary_star(system, type: 'G', subtype: 5, klass: 'V')
    _near     = build_secondary_star(primary, system, orbit_type: 2, type: 'M', subtype: 8, klass: 'V')

    p_config = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']

    assert_not_nil p_config['near'], 'Expected near secondary star key'
    assert_equal 'M8', p_config['near']['type']
  end

  test 'exports companion star' do
    system    = StarSystem.create!(parsec: @parsec, meta: {})
    primary   = build_primary_star(system, type: 'G', subtype: 2, klass: 'V')
    _comp     = build_companion_star(primary, system, type: 'K', subtype: 7, klass: 'V')

    p_config = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']

    assert_not_nil p_config['companion'], 'Expected companion key'
    assert_equal 'K7', p_config['companion']['type']
  end

  # ── bodies ───────────────────────────────────────────────────────────────────

  test 'exports bodies in orbit order with full UWP codes' do
    system  = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    _outer  = build_terrestrial_planet(primary, system, orbit: 5.0, uwp: 'C534542-6')
    _inner  = build_terrestrial_planet(primary, system, orbit: 2.0, uwp: 'A786865-B')

    bodies = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']['bodies']

    assert_equal 2,           bodies.size
    assert_equal 'A786865-B', bodies[0]['uwp'], 'inner planet first'
    assert_equal 'C534542-6', bodies[1]['uwp'], 'outer planet second'
  end

  test 'marks main world body with mainWorld: true' do
    system  = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    planet  = build_terrestrial_planet(primary, system, orbit: 3.0, uwp: 'A786865-B')
    system.update!(main_world: planet)

    body = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']['bodies'].first

    assert_equal true, body['mainWorld']
  end

  test 'exports gas giant with correct size label' do
    system    = StarSystem.create!(parsec: @parsec, meta: {})
    primary   = build_primary_star(system)
    gas_giant = GasGiant.create!(orbiting: primary, star_system: system, orbit: 6.0)
    gas_giant.code = 'GM'
    gas_giant.save!

    body = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']['bodies'].first

    assert_equal 'medium gas giant', body['uwp']
  end

  test 'exports planetoid belt' do
    system  = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    PlanetoidBelt.create!(orbiting: primary, star_system: system, orbit: 2.5)

    body = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']['bodies'].first

    assert_equal 'planetoid belt', body['uwp']
  end

  test 'skips orbiting bodies with no body_uwp mapping' do
    system  = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    GasCloud.create!(orbiting: primary, star_system: system, orbit: 1.1)

    bodies = SubsectorBuildConfigExporter.new(@subsector).export['systems'].first['primary']['bodies']

    assert_nil bodies
  end

  # ── rogues ───────────────────────────────────────────────────────────────────

  test 'exports rogue object with correct type and coordinates' do
    Relic.create!(parsec: @parsec)

    entry = SubsectorBuildConfigExporter.new(@subsector).export['rogues'].first

    assert_equal 2,       entry['x']
    assert_equal 5,       entry['y']
    assert_equal 'relic', entry['type']
  end

  test 'exports comet rogue with comet type' do
    comet = Comet.create!(parsec: @parsec)
    comet.comet_type = 'inhabited'
    comet.save!

    entry = SubsectorBuildConfigExporter.new(@subsector).export['rogues'].first

    assert_equal 'inhabited comet', entry['type']
  end

  test 'exports comet without type as plain comet' do
    Comet.create!(parsec: @parsec)

    entry = SubsectorBuildConfigExporter.new(@subsector).export['rogues'].first

    assert_equal 'comet', entry['type']
  end

  test 'exports gas giant rogue with size code' do
    rogue = GasGiant.create!(parsec: @parsec)
    rogue.code = 'GL'
    rogue.save!

    entry = SubsectorBuildConfigExporter.new(@subsector).export['rogues'].first

    assert_equal 'large gas giant', entry['type']
  end

  # ── round-trip validation ────────────────────────────────────────────────────

  test 'exported config passes BuildConfigValidator' do
    system  = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system, type: 'G', subtype: 5, klass: 'V')
    planet  = build_terrestrial_planet(primary, system, orbit: 3.0, uwp: 'A786865-B')
    system.update!(main_world: planet)

    yaml      = SubsectorBuildConfigExporter.new(@subsector).to_yaml
    validator = BuildConfigValidator.new(yaml)

    assert validator.valid?, "Expected valid but got: #{validator.errors.inspect}"
  end

  test 'exported config with brown dwarf primary passes BuildConfigValidator' do
    system  = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system, type: 'L', subtype: 5, klass: nil)
    planet  = build_terrestrial_planet(primary, system, orbit: 3.0, uwp: 'A786865-B')
    system.update!(main_world: planet)

    yaml      = SubsectorBuildConfigExporter.new(@subsector).to_yaml
    validator = BuildConfigValidator.new(yaml)

    assert validator.valid?, "Expected valid but got: #{validator.errors.inspect}"
  end

  private

  def build_primary_star(star_system, type: 'G', subtype: 5, klass: 'V')
    star = Star.new(star_system: star_system, orbit: 0, orbit_sequence: 'A')
    star.stellar_type    = type
    star.stellar_subtype = subtype
    star.stellar_class   = klass
    star.save!
    star
  end

  def build_secondary_star(orbiting_star, star_system, orbit_type:, type: 'M', subtype: 8, klass: 'V')
    star = Star.new(orbiting: orbiting_star, star_system: star_system, orbit: orbit_type, orbit_sequence: 'B')
    star.stellar_type    = type
    star.stellar_subtype = subtype
    star.stellar_class   = klass
    star.save!
    star
  end

  def build_companion_star(primary, star_system, type: 'K', subtype: 7, klass: 'V')
    companion = Star.new(orbiting: primary, star_system: star_system, orbit: 4, orbit_sequence: 'C')
    companion.stellar_type    = type
    companion.stellar_subtype = subtype
    companion.stellar_class   = klass
    companion.save!
    primary.update!(companion: companion)
    companion
  end

  def build_terrestrial_planet(orbiting_star, star_system, orbit:, uwp:)
    planet = TerrestrialPlanet.new(orbiting: orbiting_star, star_system: star_system, orbit: orbit)
    planet.size_code          = uwp[1]
    planet.starport_code      = uwp[0]
    planet.atmosphere_code    = uwp[2].to_i(16)
    planet.hydrographics_code = uwp[3].to_i(16)
    planet.population_code    = uwp[4].to_i(16)
    planet.government_code    = uwp[5].to_i(16)
    planet.law_level_code     = uwp[6].to_i(16)
    planet.tech_level_code    = uwp[8].to_i(16)
    planet.save!
    planet
  end
end
