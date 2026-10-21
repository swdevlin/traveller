require 'test_helper'

class RingsControllerTest < AuthenticatedIntegrationTest
  setup do
    @planet = stellar_objects(:moons_test_gas_giant)
  end

  test 'should get new' do
    get new_stellar_object_ring_url(@planet)
    assert_response :success
  end

  test 'should create ring orbiting the planet' do
    assert_difference('Ring.count') do
      post stellar_object_rings_url(@planet), params: { ring: { name: 'Inner ring', orbit: 1.5, span: 0.25 } },
                                              as: :turbo_stream
    end

    ring = Ring.last
    assert_equal @planet, ring.orbiting
    assert_equal @planet.star_system_id, ring.star_system_id
    assert_equal 1.5, ring.orbit
    assert_equal 0.25, ring.span
    assert_response :success
    assert_includes response.body, '<turbo-stream action="refresh">'
  end

  test 'should not create ring without a span' do
    assert_no_difference('Ring.count') do
      post stellar_object_rings_url(@planet), params: { ring: { orbit: 1.5 } }
    end

    assert_response :unprocessable_entity
  end

  test 'should get edit' do
    ring = Ring.create!(name: 'Ring', orbiting: @planet, orbit: 1.5, data: { 'span' => 0.25 })

    get edit_ring_url(ring)
    assert_response :success
  end

  test 'should update ring' do
    ring = Ring.create!(name: 'Ring', orbiting: @planet, orbit: 1.5, data: { 'span' => 0.25 })

    patch ring_url(ring), params: { ring: { name: 'Outer ring', orbit: 3, span: 0.5 } }, as: :turbo_stream

    assert_response :success
    ring.reload
    assert_equal 'Outer ring', ring.name
    assert_equal 3.0, ring.orbit
    assert_equal 0.5, ring.span
  end

  test 'should not update ring with an invalid span' do
    ring = Ring.create!(name: 'Ring', orbiting: @planet, orbit: 1.5, data: { 'span' => 0.25 })

    patch ring_url(ring), params: { ring: { span: 0 } }

    assert_response :unprocessable_entity
    assert_equal 0.25, ring.reload.span
  end

  test 'should destroy ring' do
    ring = Ring.create!(name: 'Ring', orbiting: @planet, orbit: 1.5, data: { 'span' => 0.25 })

    assert_difference('Ring.count', -1) do
      delete ring_url(ring), as: :turbo_stream
    end

    assert_response :success
    assert_includes response.body, '<turbo-stream action="refresh">'
  end
end
