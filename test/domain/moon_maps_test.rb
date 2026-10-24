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

  test 'orbits are ellipses that grow the canvas with eccentricity' do
    moon = stellar_objects(:moons_test_significant_moon)
    circular = MoonOrbitMap.new(@planet)
    moon.update_columns(eccentricity: 0.6, au: 0.002)
    eccentric = MoonOrbitMap.new(@planet.reload)

    assert_includes eccentric.to_svg, '<ellipse'
    placement = eccentric.placements.find { |p| p.body == moon }
    assert_operator placement.ellipse[:rx], :>, placement.ellipse[:ry]
    assert_operator eccentric.size, :>=, circular.size

    # The moon is drawn on its own ellipse: its distance from the focus satisfies the conic equation.
    e = 0.6
    ell = placement.ellipse
    cx = (eccentric.size / 2.0) + ell[:offset_x]
    cy = (eccentric.size / 2.0) + ell[:offset_y]
    rot = -ell[:rotation_deg] * Math::PI / 180
    dx = placement.x - cx
    dy = placement.y - cy
    u = (dx * Math.cos(rot)) - (dy * Math.sin(rot))
    v = (dx * Math.sin(rot)) + (dy * Math.cos(rot))
    assert_in_delta 1.0, ((u / ell[:rx])**2) + ((v / ell[:ry])**2), 0.01
    assert_in_delta e, ell[:offset_x].abs <= ell[:rx] ? Math.hypot(ell[:offset_x], ell[:offset_y]) / ell[:rx] : 0, 0.01
  end
end
