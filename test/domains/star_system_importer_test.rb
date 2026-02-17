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

    # only stars in the file, so stellar object does not increase, stars increases
    assert_difference('StellarObject.count', 0) do
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

    # file only has stars, so stellar objects should remain the same but stars should increase by 3
    assert_difference('StellarObject.count', 0) do
      assert_difference('Star.count', 3) do
        data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_companion.json')))
        star_system = @importer.import!(@parsec, data)
      end
    end

    primary = star_system.stars.find_by(orbiting: nil)
    assert primary.companion.present?
    assert_equal primary.companion.orbiting, primary
  end
end
