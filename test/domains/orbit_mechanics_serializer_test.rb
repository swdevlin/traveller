# frozen_string_literal: true

require 'test_helper'

class OrbitMechanicsSerializerTest < ActiveSupport::TestCase
  setup do
    @parsec = parsecs(:one)
  end

  def create_system(name: 'Test System')
    StarSystem.create!(name: name, parsec: @parsec)
  end

  def create_star(star_system, name:, orbiting: nil, orbit: nil, au: 0, companion: nil,
                   eccentricity: nil, inclination: nil, orbit_x: nil, orbit_y: nil)
    Star.create!(
      name: name,
      star_system: star_system,
      colour: 'Yellow',
      stellar_type: 'G',
      stellar_subtype: 2,
      stellar_class: 'V',
      is_protostar: false,
      orbiting: orbiting,
      orbit: orbit,
      au: au,
      companion: companion,
      eccentricity: eccentricity,
      inclination: inclination,
      orbit_x: orbit_x,
      orbit_y: orbit_y
    )
  end

  def create_body(star, type:, name:, orbit:, eccentricity: nil, inclination: nil, orbit_x: nil, orbit_y: nil)
    attrs = {
      name: name, orbiting: star, orbit: orbit, au: OrbitToAu.convert(orbit),
      eccentricity: eccentricity, inclination: inclination, orbit_x: orbit_x, orbit_y: orbit_y
    }
    attrs.merge!(size_code: 5, atmosphere_code: 6, hydrographics_code: 3) if type == 'TerrestrialPlanet'
    type.constantize.create!(**attrs)
  end

  test 'primary star gets orbitType 0' do
    ss = create_system
    primary = create_star(ss, name: 'Sol')
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload
    primary.reload

    payload = OrbitMechanicsSerializer.new(ss).serialize

    assert_equal 0, payload['primaryStar']['orbitType']
    assert_equal primary.orbit_sequence, payload['primaryStar']['orbitSequence']
  end

  test 'close/near/far secondary stars get numeric orbitType matching orbit rank' do
    ss = create_system
    primary = create_star(ss, name: 'Sol')
    close = create_star(ss, name: 'Close', orbiting: primary, orbit: 1)
    near = create_star(ss, name: 'Near', orbiting: primary, orbit: 2)
    far = create_star(ss, name: 'Far', orbiting: primary, orbit: 3)
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload
    [close, near, far].each(&:reload)

    payload = OrbitMechanicsSerializer.new(ss).serialize
    by_orbit_seq = payload['primaryStar']['stellarObjects'].index_by { |n| n['orbitSequence'] }

    assert_equal 1, by_orbit_seq[close.orbit_sequence]['orbitType']
    assert_equal 2, by_orbit_seq[near.orbit_sequence]['orbitType']
    assert_equal 3, by_orbit_seq[far.orbit_sequence]['orbitType']
  end

  test 'companion star gets orbitType 4 regardless of orbit rank' do
    ss = create_system
    primary = create_star(ss, name: 'Sol')
    companion = create_star(ss, name: 'Companion', orbiting: primary, orbit: 1)
    primary.update!(companion: companion)
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload
    companion.reload

    payload = OrbitMechanicsSerializer.new(ss).serialize
    companion_node = payload['primaryStar']['stellarObjects'].find { |n| n['orbitSequence'] == companion.orbit_sequence }

    assert_equal 4, companion_node['orbitType']
  end

  test 'planet nodes use their own orbit_type and include eccentricity/inclination/orbitPosition' do
    ss = create_system
    primary = create_star(ss, name: 'Sol')
    planet = create_body(primary, type: 'TerrestrialPlanet', name: 'Earth', orbit: 3,
                                   eccentricity: 0.05, inclination: 2.1, orbit_x: 10.0, orbit_y: -5.0)
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload
    planet.reload

    payload = OrbitMechanicsSerializer.new(ss).serialize
    planet_node = payload['primaryStar']['stellarObjects'].find { |n| n['orbitSequence'] == planet.orbit_sequence }

    assert_equal 11, planet_node['orbitType']
    assert_equal 0.05, planet_node['eccentricity']
    assert_equal 2.1, planet_node['inclination']
    assert_equal({ 'x' => 10.0, 'y' => -5.0 }, planet_node['orbitPosition'])
  end

  test 'moons are nested under their planet and never carry orbitPosition3d' do
    ss = create_system
    primary = create_star(ss, name: 'Sol')
    planet = create_body(primary, type: 'TerrestrialPlanet', name: 'Earth', orbit: 3)
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload
    planet.reload
    moon = Moon.create!(name: 'Luna', orbiting: planet, orbit: 1, au: OrbitToAu.convert(1), size_code: '3',
                         eccentricity: 0.01, inclination: 5, orbit_sequence: "#{planet.orbit_sequence}.1")

    payload = OrbitMechanicsSerializer.new(ss).serialize
    planet_node = payload['primaryStar']['stellarObjects'].find { |n| n['orbitSequence'] == planet.orbit_sequence }
    moon_node = planet_node['moons'].sole

    assert_equal moon.orbit_sequence, moon_node['orbitSequence']
    assert_not payload.to_s.include?('orbitPosition3d')
  end
end
