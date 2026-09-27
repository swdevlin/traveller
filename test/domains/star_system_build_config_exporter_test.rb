# frozen_string_literal: true

require 'test_helper'
require 'json'

class StarSystemBuildConfigExporterTest < ActiveSupport::TestCase
  def setup
    @parsec = parsecs(:one)
  end

  # ── close/near/far secondaries ──────────────────────────────────────────────

  test 'exports close secondary star with its own bodies' do
    system = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    close = build_secondary_star(primary, system, orbit: 1)
    build_terrestrial_planet(close, system, orbit: 2.0, uwp: 'A786865-B')

    config = StarSystemBuildConfigExporter.new(system).export

    assert_not_nil config['primary']['close'], 'Expected close secondary star key'
    assert_equal 1, config['primary']['close']['bodies'].size
    assert_equal 'A786865-B', config['primary']['close']['bodies'].first['uwp']
  end

  test 'exports near secondary star with its own bodies' do
    system = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    # Orbit# 8 falls in the 'near' band (6-11) per World Builder's Handbook pg. 27.
    near = build_secondary_star(primary, system, orbit: 8)
    build_terrestrial_planet(near, system, orbit: 2.0, uwp: 'A786865-B')

    config = StarSystemBuildConfigExporter.new(system).export

    assert_not_nil config['primary']['near'], 'Expected near secondary star key'
    assert_equal 1, config['primary']['near']['bodies'].size
    assert_equal 'A786865-B', config['primary']['near']['bodies'].first['uwp']
  end

  test 'exports far secondary star with a realistic (non-integer-3) orbit and its own bodies' do
    system = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    # Orbit# 13.9, matching a real generator payload for a far secondary
    # (test/fixtures/files/star_system_import_complete.json) - proves the role
    # is derived from the Orbit# band, not from an exact integer match.
    far = build_secondary_star(primary, system, orbit: 13.9)
    build_terrestrial_planet(far, system, orbit: 1.0, uwp: 'C534542-6')

    config = StarSystemBuildConfigExporter.new(system).export

    assert_not_nil config['primary']['far'], 'Expected far secondary star key'
    assert_equal 1, config['primary']['far']['bodies'].size
    assert_equal 'C534542-6', config['primary']['far']['bodies'].first['uwp']
  end

  test 'far secondary star with its own nested companion' do
    system = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    far = build_secondary_star(primary, system, orbit: 14)
    build_companion_star(far, system, type: 'M', subtype: 4, klass: 'V')

    config = StarSystemBuildConfigExporter.new(system).export

    assert_not_nil config['primary']['far']['companion'], 'Expected companion of far secondary'
    assert_equal 'M4', config['primary']['far']['companion']['type']
  end

  # ── tight-binary companion ──────────────────────────────────────────────────

  test 'exports primary companion star with its own bodies' do
    system = StarSystem.create!(parsec: @parsec, meta: {})
    primary = build_primary_star(system)
    companion = build_companion_star(primary, system, type: 'K', subtype: 7, klass: 'V')
    build_terrestrial_planet(companion, system, orbit: 1.0, uwp: 'E567000-0')

    config = StarSystemBuildConfigExporter.new(system).export

    assert_not_nil config['primary']['companion'], 'Expected companion key'
    assert_equal 'K7', config['primary']['companion']['type']
    assert_equal 1, config['primary']['companion']['bodies'].size
    assert_equal 'E567000-0', config['primary']['companion']['bodies'].first['uwp']
  end

  # ── round-trip regression ───────────────────────────────────────────────────

  test 'derived build config includes a far secondary star and its bodies after import' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_nested.json')))
    star_system = StarSystemImporter.new.import!(@parsec, data)

    config = StarSystemBuildConfigExporter.new(star_system).export

    assert_not_nil config['primary']['far'], 'Expected far secondary star to survive export'
    assert config['primary']['far']['bodies'].present?, 'Expected far secondary to keep its bodies'
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

  def build_secondary_star(orbiting_star, star_system, orbit:, type: 'M', subtype: 8, klass: 'V')
    star = Star.new(orbiting: orbiting_star, star_system: star_system, orbit: orbit, orbit_sequence: 'B')
    star.stellar_type    = type
    star.stellar_subtype = subtype
    star.stellar_class   = klass
    star.save!
    star
  end

  def build_companion_star(primary, star_system, type: 'K', subtype: 7, klass: 'V')
    companion = Star.new(orbiting: primary, star_system: star_system, orbit: 0.3, orbit_sequence: 'C')
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
