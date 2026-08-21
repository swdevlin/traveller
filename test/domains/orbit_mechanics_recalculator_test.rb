# frozen_string_literal: true

require 'test_helper'

class OrbitMechanicsRecalculatorTest < ActiveSupport::TestCase
  setup do
    @parsec = parsecs(:one)
    @base = Rails.application.config.x.generator_service
  end

  def create_system(name: 'Test System')
    StarSystem.create!(name: name, parsec: @parsec)
  end

  def create_star(star_system, name:, orbiting: nil, orbit: nil, au: 0)
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
      au: au
    )
  end

  def create_body(star, type:, name:, orbit:)
    attrs = { name: name, orbiting: star, orbit: orbit, au: OrbitToAu.convert(orbit) }
    attrs.merge!(size_code: 5, atmosphere_code: 6, hydrographics_code: 3) if type == 'TerrestrialPlanet'
    type.constantize.create!(**attrs)
  end

  def stub_orbit_mechanics(body)
    stub_request(:post, "#{@base}/orbit_mechanics")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body.to_json)
  end

  test 'writes orbit_x/orbit_y and eccentricity/inclination back onto matched records' do
    ss = create_system
    primary = create_star(ss, name: 'Sol')
    planet = create_body(primary, type: 'TerrestrialPlanet', name: 'Earth', orbit: 3)
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload
    primary.reload
    planet.reload

    stub_orbit_mechanics(
      'primaryStar' => {
        'orbitSequence' => primary.orbit_sequence,
        'orbitPosition' => { 'x' => 0, 'y' => 0 },
        'stellarObjects' => [
          {
            'orbitSequence' => planet.orbit_sequence,
            'eccentricity' => 0.09,
            'inclination' => 4.4,
            'orbitPosition' => { 'x' => 123.4, 'y' => -56.7 },
            'moons' => []
          }
        ]
      }
    )

    result = OrbitMechanicsRecalculator.new(ss, GeneratorService.new).recalculate!

    assert_predicate result, :success?
    planet.reload
    assert_in_delta 123.4, planet.orbit_x, 0.001
    assert_in_delta(-56.7, planet.orbit_y, 0.001)
    assert_in_delta 0.09, planet.eccentricity, 0.001
    assert_in_delta 4.4, planet.inclination, 0.001
  end

  test 'primary star position is left untouched' do
    ss = create_system
    primary = create_star(ss, name: 'Sol')
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload
    primary.reload

    stub_orbit_mechanics(
      'primaryStar' => {
        'orbitSequence' => primary.orbit_sequence,
        'orbitPosition' => { 'x' => 999, 'y' => 999 },
        'stellarObjects' => []
      }
    )

    result = OrbitMechanicsRecalculator.new(ss, GeneratorService.new).recalculate!

    assert_predicate result, :success?
    primary.reload
    assert_nil primary.orbit_x
    assert_nil primary.orbit_y
  end

  test 'unmatched orbitSequence is skipped without raising' do
    ss = create_system
    primary = create_star(ss, name: 'Sol')
    planet = create_body(primary, type: 'TerrestrialPlanet', name: 'Earth', orbit: 3)
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload
    primary.reload
    planet.reload

    stub_orbit_mechanics(
      'primaryStar' => {
        'orbitSequence' => primary.orbit_sequence,
        'stellarObjects' => [
          { 'orbitSequence' => 'not-a-real-sequence', 'orbitPosition' => { 'x' => 1, 'y' => 1 } }
        ]
      }
    )

    result = nil
    assert_nothing_raised { result = OrbitMechanicsRecalculator.new(ss, GeneratorService.new).recalculate! }

    assert_predicate result, :success?
    planet.reload
    assert_nil planet.orbit_x
    assert_nil planet.orbit_y
  end

  test 'returns a failure Result when the service call fails' do
    ss = create_system
    create_star(ss, name: 'Sol')
    OrbitSequenceAssigner.new(ss).assign!
    ss.reload

    stub_request(:post, "#{@base}/orbit_mechanics")
      .to_return(status: 400, headers: { 'Content-Type' => 'application/json' }, body: { error: 'bad tree' }.to_json)

    result = OrbitMechanicsRecalculator.new(ss, GeneratorService.new).recalculate!

    assert_not result.success?
    assert result.errors.present?
  end
end
