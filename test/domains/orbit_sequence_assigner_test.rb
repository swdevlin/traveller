# frozen_string_literal: true

require 'test_helper'

class OrbitSequenceAssignerTest < ActiveSupport::TestCase
  setup do
    @parsec = parsecs(:one)
  end

  def create_system(name: 'Test System')
    StarSystem.create!(name: name, parsec: @parsec)
  end

  def create_star(star_system, name:, orbiting: nil, orbit: 0, au: 0, companion: nil)
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
      companion: companion
    )
  end

  def create_body(star, type:, name:, orbit:)
    attrs = { name: name, orbiting: star, orbit: orbit, au: OrbitToAu.convert(orbit) }
    attrs.merge!(size_code: 5, atmosphere_code: 6, hydrographics_code: 3) if type == 'TerrestrialPlanet'
    type.constantize.create!(**attrs)
  end

  test 'single star system assigns A to primary' do
    ss = create_system
    star = create_star(ss, name: 'Sol')

    OrbitSequenceAssigner.new(ss).assign!
    star.reload

    assert_equal 'A', star.orbit_sequence
  end

  test 'single star with bodies assigns Roman numerals in orbit order' do
    ss = create_system
    star = create_star(ss, name: 'Sol')
    earth = create_body(star, type: 'TerrestrialPlanet', name: 'Earth', orbit: 3)
    mars = create_body(star, type: 'TerrestrialPlanet', name: 'Mars', orbit: 4)
    belt = create_body(star, type: 'PlanetoidBelt', name: 'Belt', orbit: 5)

    OrbitSequenceAssigner.new(ss).assign!
    [earth, mars, belt].each(&:reload)

    assert_equal 'A I', earth.orbit_sequence
    assert_equal 'A II', mars.orbit_sequence
    assert_equal 'A III', belt.orbit_sequence
  end

  test 'binary system assigns A and B' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    secondary = create_star(ss, name: 'Beta', orbiting: primary, orbit: 8, au: 20)

    OrbitSequenceAssigner.new(ss).assign!
    [primary, secondary].each(&:reload)

    assert_equal 'A', primary.orbit_sequence
    assert_equal 'B', secondary.orbit_sequence
  end

  test 'primary with companion assigns Ab to companion' do
    ss = create_system
    companion_star = create_star(ss, name: 'Alpha-b', orbit: 0, au: 0)
    primary = create_star(ss, name: 'Alpha', companion: companion_star)
    companion_star.update_column(:orbiting_id, primary.id)

    OrbitSequenceAssigner.new(ss).assign!
    [primary, companion_star].each(&:reload)

    assert_equal 'A', primary.orbit_sequence
    assert_equal 'Ab', companion_star.orbit_sequence
  end

  test 'primary with companion uses Aab prefix for bodies' do
    ss = create_system
    companion_star = create_star(ss, name: 'Alpha-b', orbit: 0, au: 0)
    primary = create_star(ss, name: 'Alpha', companion: companion_star)
    companion_star.update_column(:orbiting_id, primary.id)

    planet = create_body(primary, type: 'TerrestrialPlanet', name: 'Planet', orbit: 3)

    OrbitSequenceAssigner.new(ss).assign!
    planet.reload

    assert_equal 'Aab I', planet.orbit_sequence
  end

  test 'bodies between stars use accumulated prefix' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    inner = create_body(primary, type: 'TerrestrialPlanet', name: 'Inner', orbit: 2)
    secondary = create_star(ss, name: 'Beta', orbiting: primary, orbit: 5, au: 5.2)
    outer = create_body(primary, type: 'GasGiant', name: 'Outer', orbit: 10)

    OrbitSequenceAssigner.new(ss).assign!
    [inner, outer].each(&:reload)

    assert_equal 'A I', inner.orbit_sequence
    assert_equal 'AB II', outer.orbit_sequence
  end

  test 'bodies orbiting secondary star use secondary prefix' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    secondary = create_star(ss, name: 'Beta', orbiting: primary, orbit: 8, au: 20)
    planet = create_body(secondary, type: 'TerrestrialPlanet', name: 'Beta-planet', orbit: 1)

    OrbitSequenceAssigner.new(ss).assign!
    planet.reload

    assert_equal 'B I', planet.orbit_sequence
  end

  test 'three star system assigns A B C in orbit order' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    near = create_star(ss, name: 'Gamma', orbiting: primary, orbit: 10, au: 77)
    close = create_star(ss, name: 'Beta', orbiting: primary, orbit: 5, au: 5.2)

    OrbitSequenceAssigner.new(ss).assign!
    [primary, close, near].each(&:reload)

    assert_equal 'A', primary.orbit_sequence
    assert_equal 'B', close.orbit_sequence
    assert_equal 'C', near.orbit_sequence
  end

  test 'secondary with companion assigns Bb to companion' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    comp = create_star(ss, name: 'Beta-b', orbiting: primary, orbit: 5, au: 5.2)
    secondary = create_star(ss, name: 'Beta', orbiting: primary, orbit: 5, au: 5.2, companion: comp)
    comp.update_column(:orbiting_id, secondary.id)
    # Fix: secondary orbits primary, not itself
    secondary.update_column(:orbiting_id, primary.id)

    OrbitSequenceAssigner.new(ss).assign!
    [secondary, comp].each(&:reload)

    assert_equal 'B', secondary.orbit_sequence
    assert_equal 'Bb', comp.orbit_sequence
  end

  test 'secondary with companion uses Bab prefix for its bodies' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    comp = create_star(ss, name: 'Beta-b', orbit: 0, au: 0)
    secondary = create_star(ss, name: 'Beta', orbiting: primary, orbit: 5, au: 5.2, companion: comp)
    comp.update_column(:orbiting_id, secondary.id)

    planet = create_body(secondary, type: 'TerrestrialPlanet', name: 'Beta-planet', orbit: 1)

    OrbitSequenceAssigner.new(ss).assign!
    planet.reload

    assert_equal 'Bab I', planet.orbit_sequence
  end

  test 'destroying a body reassigns orbit sequences' do
    ss = create_system
    star = create_star(ss, name: 'Sol')
    mercury = create_body(star, type: 'TerrestrialPlanet', name: 'Mercury', orbit: 1)
    venus = create_body(star, type: 'TerrestrialPlanet', name: 'Venus', orbit: 2)
    earth = create_body(star, type: 'TerrestrialPlanet', name: 'Earth', orbit: 3)

    OrbitSequenceAssigner.new(ss).assign!
    [mercury, venus, earth].each(&:reload)

    assert_equal 'A I', mercury.orbit_sequence
    assert_equal 'A II', venus.orbit_sequence
    assert_equal 'A III', earth.orbit_sequence

    venus.destroy!
    [mercury, earth].each(&:reload)

    assert_equal 'A I', mercury.orbit_sequence
    assert_equal 'A II', earth.orbit_sequence
  end

  test 'body numbering is per star not global' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    p1 = create_body(primary, type: 'TerrestrialPlanet', name: 'A-1', orbit: 1)
    secondary = create_star(ss, name: 'Beta', orbiting: primary, orbit: 5, au: 5.2)
    b1 = create_body(secondary, type: 'TerrestrialPlanet', name: 'B-1', orbit: 1)
    b2 = create_body(secondary, type: 'TerrestrialPlanet', name: 'B-2', orbit: 2)

    OrbitSequenceAssigner.new(ss).assign!
    [p1, b1, b2].each(&:reload)

    assert_equal 'A I', p1.orbit_sequence
    assert_equal 'B I', b1.orbit_sequence
    assert_equal 'B II', b2.orbit_sequence
  end
end
