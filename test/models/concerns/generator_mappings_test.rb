# frozen_string_literal: true

require 'test_helper'

class GeneratorMappingsTest < ActiveSupport::TestCase
  test 'assign_data_from_generator keeps the orbit sequence when the payload has none' do
    planet = TerrestrialPlanet.new(orbit_sequence: 'A II')

    planet.assign_data_from_generator({ 'orbit' => 2.0, 'au' => 1.0 })

    assert_equal 'A II', planet.orbit_sequence
  end

  test 'assign_data_from_generator takes the orbit sequence from the payload when present' do
    planet = TerrestrialPlanet.new(orbit_sequence: 'A II')

    planet.assign_data_from_generator({ 'orbit' => 2.0, 'au' => 1.0, 'orbitSequence' => 'A III' })

    assert_equal 'A III', planet.orbit_sequence
  end
end
