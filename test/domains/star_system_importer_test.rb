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

    assert_difference('StellarObject.count', 2) do
      assert_difference('StarSystem.count', 1) do
        data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
        star_system = @importer.import!(@parsec, data)
      end
    end

    assert_equal @parsec, star_system.parsec
    assert_equal 'New Star System', star_system.name
  end

  test 'every stellar object in a star system points to the star system' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_minimal.json')))
    star_system = @importer.import!(@parsec, data)

    # Every object in the star system points to the star system
    assert_equal 2, star_system.stellar_objects.count

    primary = star_system.stellar_objects.find_by!(type: 'Star')
    orbiters = star_system.stellar_objects.where.not(id: primary.id)

    assert_equal 1, orbiters.count

    orbiters.each do |so|
      assert_equal star_system, so.star_system
      assert_equal primary, so.orbiting
    end
  end

  test 'nested stellar object orbits parent star, not primary star' do
    data = JSON.parse(File.read(Rails.root.join('test/fixtures/files/star_system_import_nested.json')))
    star_system = @importer.import!(@parsec, data)

    # Every object in the star system points to the star system
    assert_equal 4, star_system.stellar_objects.count

    primary = star_system.stellar_objects.find_by!(type: 'Star', orbiting_id: nil)
    secondary = star_system.stellar_objects.where(type: 'Star').where.not(orbiting_id: nil).sole

    assert_equal 2, primary.stellar_objects.count
    assert_equal 1, secondary.stellar_objects.count
  end

end
