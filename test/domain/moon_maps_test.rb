require 'test_helper'

class MoonMapsTest < ActiveSupport::TestCase
  setup do
    @planet = stellar_objects(:moons_test_gas_giant)
    Ring.create!(name: 'Halo', orbiting: @planet, orbit: 1.5, data: { 'span' => 0.4 })
  end

  test 'orbit map places every moon and draws the ring' do
    map = MoonOrbitMap.new(@planet, link_builder: ->(moon) { "/stellar_objects/#{moon.id}" })
    svg = map.to_svg

    assert_equal 2, map.placements.size
    assert_includes svg, 'Significant Moon'
    assert_includes svg, 'Insignificant Moon'
    assert_includes svg, 'Halo'
    assert_includes svg, %(href="/stellar_objects/#{stellar_objects(:moons_test_significant_moon).id}")
  end

  test 'significant only drops small moons but keeps rings' do
    svg = MoonOrbitMap.new(@planet, significant_only: true).to_svg

    assert_includes svg, 'Significant Moon'
    assert_includes svg, 'Halo'
    assert_not_includes svg, 'Insignificant Moon'
  end

  test 'inline images are embedded for the rasterised map' do
    svg = MoonOrbitMap.new(@planet, inline_images: true).to_svg

    assert_no_match %r{href="/stellar_objects/}, svg
  end

  test 'maps with no moons still render' do
    planet = stellar_objects(:cities_test_planet)

    assert_includes MoonOrbitMap.new(planet).to_svg, '</svg>'
  end
end
