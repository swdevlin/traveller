require 'test_helper'

class RingTest < ActiveSupport::TestCase
  setup do
    @planet = stellar_objects(:moons_test_gas_giant)
  end

  def build_ring(**attrs)
    Ring.new({ name: 'Ring', orbiting: @planet, orbit: 1.5, data: { 'span' => 0.25 } }.merge(attrs))
  end

  test 'span is stored as a float' do
    ring = build_ring(data: { 'span' => '0.3' })
    ring.valid?

    assert_equal 0.3, ring.span
  end

  test 'span must be positive' do
    assert_not build_ring(data: {}).valid?
    assert_not build_ring(data: { 'span' => 0 }).valid?
  end

  test 'moons_and_rings lists both in orbit order' do
    ring = build_ring(orbit: 0.5)
    ring.save!
    far_ring = build_ring(orbit: 50.0)
    far_ring.save!

    list = @planet.moons_and_rings.to_a

    assert_equal list.map(&:orbit), list.map(&:orbit).sort
    assert_equal ring, list.first
    assert_equal far_ring, list.last
  end

  test 'significant_only hides small moons but keeps rings' do
    @planet.moons.update_all(size_code: '0')
    ring = build_ring
    ring.save!

    assert_equal [ring], @planet.moons_and_rings(significant_only: true).to_a
  end

  test 'rings have no orbit sequence and do not affect the moon numbering' do
    ring = build_ring(orbit: 0.01)
    ring.save!
    seq = @planet.reload.orbit_sequence

    assert_nil ring.reload.orbit_sequence
    assert_equal (1..@planet.moons.count).map { |i| "#{seq}.#{i}" }, @planet.moons.order(:orbit).map(&:orbit_sequence)
  end

  test 'ringed? is true for a planet with a ring record or the generator flag' do
    assert_not @planet.ringed?

    build_ring.save!
    assert @planet.reload.ringed?

    Ring.where(orbiting_id: @planet.id).destroy_all
    @planet.update_column(:data, (@planet.data || {}).merge('hasRing' => true))
    assert @planet.reload.ringed?
  end

  test 'distance and width in km use the parent diameter' do
    @planet.diameter = 100_000
    ring = build_ring(orbit: 1.27, data: { 'span' => 0.12 })

    assert_in_delta 127_000, ring.distance_km, 0.001
    assert_in_delta 12_000, ring.width_km, 0.001
  end
end
