# frozen_string_literal: true

require 'test_helper'
require 'json'

class StarSystemImporterTest < ActiveSupport::TestCase
  def setup
    super
    @importer = StarSystemImporter.new
    @parsec = parsecs(:one)
  end

  test 'star system belongs to parsec' do
    star_system = nil

    # Stars are now StellarObjects, so both counts increase
    assert_difference('StellarObject.count', 2) do
      assert_difference('Star.count', 2) do
        assert_difference('StarSystem.count', 1) do
          data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
          star_system = @importer.import!(@parsec, data)
        end
      end
    end

    assert_equal @parsec, star_system.parsec
    assert_equal 'Kiusah', star_system.name
  end

  test 'every stellar object in a star system points to the star system' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    star_system = @importer.import!(@parsec, data)

    # Only stars in the minimal file
    assert_equal 0, star_system.stellar_objects.count
    assert_equal 2, star_system.stars.count

    primary = star_system.stars.where(orbiting_id: nil).sole
    orbiters = star_system.stellar_objects.where.not(id: primary.id)

    assert_equal 0, orbiters.count

    orbiters.each do |so|
      assert_equal star_system, so.star_system
      assert_equal primary, so.orbiting
    end
  end

  test 'nested stellar object orbits parent star, not primary star' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_nested.json')))
    star_system = @importer.import!(@parsec, data)

    # Every object in the star system points to the star system
    assert_equal 2, star_system.stellar_objects.count
    assert_equal 2, star_system.stars.count

    primary = star_system.stars.where(orbiting_id: nil).sole
    secondary = Star.where(orbiting: primary).sole

    assert_equal 1, primary.stellar_objects.count
    assert_equal 1, secondary.stellar_objects.count
  end

  test 'companion added' do
    star_system = nil

    # Stars are now StellarObjects, so both counts increase
    assert_difference('StellarObject.count', 3) do
      assert_difference('Star.count', 3) do
        data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_companion.json')))
        star_system = @importer.import!(@parsec, data)
      end
    end

    primary = star_system.primary_star
    assert primary.companion.present?
    assert_equal primary.companion.orbiting, primary
  end

  test 'moon is set as main world when mainWorldOrbitSequence matches a moon' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_moon_main_world.json')))
    star_system = @importer.import!(@parsec, data)

    assert_not_nil star_system.main_world, 'Expected main_world to be set'
    assert_instance_of Moon, star_system.main_world
    assert_equal 'A I m1', star_system.main_world.orbit_sequence
    assert_equal 'B100477-C', star_system.main_world.uwp
  end

  test 'facilities assigned from generator response bases when config_bases is not given' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    data['bases'] = [facilities(:one).code]
    star_system = @importer.import!(@parsec, data)

    assert_equal [facilities(:one).code], star_system.facilities.pluck(:code)
  end

  test 'config_bases takes precedence over generator response bases' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    data['bases'] = [facilities(:one).code]
    star_system = @importer.import!(@parsec, data, config_bases: [facilities(:two).code])

    assert_equal [facilities(:two).code], star_system.facilities.pluck(:code)
  end

  test 'empty config_bases overrides generator response bases with no facilities' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    data['bases'] = [facilities(:one).code]
    star_system = @importer.import!(@parsec, data, config_bases: [])

    assert_empty star_system.facilities
  end

  test 'unknown facility codes are silently skipped' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    star_system = @importer.import!(@parsec, data, config_bases: %w[NOT-A-CODE])

    assert_empty star_system.facilities
  end

  test 'stale empty string bases from generator yields no facilities without error' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    data['bases'] = ''
    star_system = @importer.import!(@parsec, data)

    assert_empty star_system.facilities
  end

  test 'reimport recreates facilities from config_bases after deleting existing ones' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    star_system = @importer.import!(@parsec, data)
    StarSystemFacility.create!(star_system: star_system, facility: facilities(:one))

    reimport_data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    @importer.reimport!(star_system, reimport_data, config_bases: [facilities(:two).code])

    assert_equal [facilities(:two).code], star_system.facilities.pluck(:code)
  end

  test 'reimport falls back to generator response bases when config_bases is nil' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    star_system = @importer.import!(@parsec, data)

    reimport_data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    reimport_data['bases'] = [facilities(:two).code]
    @importer.reimport!(star_system, reimport_data)

    assert_equal [facilities(:two).code], star_system.facilities.pluck(:code)
  end

  test 'planetoids are linked to their belt via planetoid_belt_id' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_planetoid.json')))
    star_system = @importer.import!(@parsec, data)

    belt = PlanetoidBelt.find_by(star_system_id: star_system.id)
    assert belt.present?, 'Expected a PlanetoidBelt to be imported'

    planetoids = Planetoid.where(star_system_id: star_system.id)
    assert_equal 2, planetoids.count

    planetoids.each do |planetoid|
      assert_equal belt.id, planetoid.planetoid_belt_id,
        "Expected planetoid #{planetoid.orbit_sequence} to reference the belt"
    end
  end
end
