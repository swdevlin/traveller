# frozen_string_literal: true

require 'test_helper'

class StarOrbitMapTest < ActiveSupport::TestCase
  setup do
    @system = StarSystem.create!(name: 'Test System', parsec: parsecs(:one))
    @star = create_star('Sol')
  end

  def create_star(name, orbiting: nil, orbit: nil, au: nil)
    Star.create!(
      name: name, star_system: @system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2,
      stellar_class: 'V', is_protostar: false, orbiting: orbiting, orbit: orbit, au: au
    )
  end

  def create_giant(name, orbit, au: orbit * 0.5)
    GasGiant.create!(name: name, orbiting: @star, orbit: orbit, au: au, code: 'GM')
  end

  def centre(map) = map.size / 2.0

  def distance_from_centre(map, placement)
    Math.hypot(placement.x - centre(map), placement.y - centre(map))
  end

  def parse(map) = Nokogiri::XML(map.to_svg) { |config| config.strict }

  test 'every theme has a palette, and an unknown theme falls back to the default' do
    assert_equal ApplicationHelper::THEMES.keys.sort, OrbitMapTheme::PALETTES.keys.sort
    assert_equal OrbitMapTheme.palette('dark'), OrbitMapTheme.palette('no-such-theme')
    assert_equal OrbitMapTheme.palette('dark'), OrbitMapTheme.palette(nil)
  end

  test 'a lone star gives a minimum size map with just the star' do
    map = StarOrbitMap.new(@star)

    assert_equal StarOrbitMap::MIN_SIZE, map.size
    assert_empty map.placements
    assert_equal 1, parse(map).css('image').size, 'only the star itself is drawn'
    assert_empty parse(map).css('ellipse')
  end

  test 'a single object sits on the first ring, at its real bearing' do
    giant = create_giant('Big', 2)
    giant.update_columns(orbit_x: 0.0, orbit_y: 150_000_000.0)

    map = StarOrbitMap.new(@star.reload)
    placement = map.placements.sole

    step = (map.size / 2.0 - StarOrbitMap::EDGE_MARGIN - StarOrbitMap::INNER_PX) / 2
    assert_in_delta StarOrbitMap::INNER_PX + step, distance_from_centre(map, placement), 0.01
    # +y is straight down the page
    assert_in_delta centre(map), placement.x, 0.01
    assert_operator placement.y, :>, centre(map)
  end

  test 'objects with no position are fanned out by golden angle' do
    create_giant('One', 1)
    create_giant('Two', 2)

    first, second = StarOrbitMap.new(@star.reload).placements.sort_by { |p| p.child.orbit }

    assert_in_delta 0.0, Math.atan2(first.y - 400, first.x - 400) - 0, Math::PI
    assert_in_delta StarOrbitMap::GOLDEN_ANGLE,
                    Math.atan2(second.y - 400, second.x - 400) - Math.atan2(first.y - 400, first.x - 400),
                    0.01
  end

  test 'canvas grows with the number of rings and keeps them apart' do
    20.times { |i| create_giant("Giant #{i}", i + 1) }

    map = StarOrbitMap.new(@star.reload)

    assert_operator map.size, :>, StarOrbitMap::MIN_SIZE
    radii = map.placements.map(&:pixel_r).sort
    assert_equal 20, radii.size
    radii.each_cons(2) do |inner, outer|
      assert_operator outer - inner, :>=, StarOrbitMap::RING_SPACING_PX / 2.0
    end
    assert_operator radii.last + StarOrbitMap::EDGE_MARGIN, :<=, map.size / 2.0
  end

  test 'a few objects fit the minimum size' do
    3.times { |i| create_giant("Giant #{i}", i + 1) }

    assert_equal StarOrbitMap::MIN_SIZE, StarOrbitMap.new(@star.reload).size
  end

  test 'rings are ordered by real distance from the star' do
    far = create_giant('Far', 3, au: 5.0)
    near = create_giant('Near', 1, au: 0.5)
    far.update_columns(orbit_x: 5.0 * StellarConstants::AU_TO_KM, orbit_y: 0.0)
    near.update_columns(orbit_x: 0.5 * StellarConstants::AU_TO_KM, orbit_y: 0.0)

    placements = StarOrbitMap.new(@star.reload).placements.index_by { |p| p.child.object.name }

    assert_operator placements['Near'].pixel_r, :<, placements['Far'].pixel_r
  end

  test 'a distant companion is pinned to the outer ring beyond the core' do
    create_giant('Close', 1)
    create_giant('Closer', 2)
    companion = create_star('Beta', orbiting: @star, orbit: 12, au: 40.0)
    @star.update!(companion: companion)

    map = StarOrbitMap.new(@star.reload)
    by_name = map.placements.index_by { |p| p.child.object.name }
    outer_px = map.size / 2.0 - StarOrbitMap::EDGE_MARGIN

    assert_in_delta outer_px, by_name['Beta'].pixel_r, 0.01
    assert_operator by_name['Closer'].pixel_r, :<, by_name['Beta'].pixel_r - 20
  end

  test 'planetoids of a belt hug the belt ring instead of taking their own' do
    create_giant('Giant', 1)
    belt = PlanetoidBelt.create!(name: 'Belt', orbiting: @star, orbit: 2, au: 1.0)
    rock = Planetoid.create!(name: 'Rock', orbiting: @star, orbit: 2, au: 1.0, size_code: 'S', planetoid_belt_id: belt.id)

    map = StarOrbitMap.new(@star.reload)
    belt_placement = map.placements.find { |p| p.child.object == belt }
    rock_placement = map.placements.find { |p| p.child.object == rock }

    assert_equal 2, map.placements.reject { |p| p.child.object == rock }.size
    assert_in_delta belt_placement.pixel_r, rock_placement.pixel_r, StarOrbitMap::PLANETOID_SPREAD_PX
  end

  test 'a planetoid whose belt is not on the map takes a ring of its own' do
    create_giant('Giant', 1)
    Planetoid.create!(name: 'Stray', orbiting: @star, orbit: 2, au: 1.0, size_code: 'S', planetoid_belt_id: 0)

    map = StarOrbitMap.new(@star.reload)
    radii = map.placements.map(&:pixel_r)

    assert_equal 2, radii.uniq.size
    assert_includes map.placements.map { |p| p.child.object.name }, 'Stray'
  end

  test 'moons and the objects orbiting a companion are not drawn' do
    giant = create_giant('Giant', 1)
    Moon.create!(name: 'Moon', orbiting: giant, orbit: 1, au: 0.01, size_code: 'S')
    companion = create_star('Beta', orbiting: @star, orbit: 6, au: 10.0)
    GasGiant.create!(name: 'Beta Giant', orbiting: companion, orbit: 1, au: 0.5, code: 'GS')

    names = StarOrbitMap.new(@star.reload).placements.map { |p| p.child.object.name }

    assert_equal %w[Giant Beta].sort, names.sort
  end

  test 'without a link builder the svg has no links' do
    create_giant('Giant', 1)

    assert_empty parse(StarOrbitMap.new(@star.reload)).css('a')
  end

  test 'with a link builder every object but the centre star is linked' do
    giant = create_giant('Giant', 1)
    belt = PlanetoidBelt.create!(name: 'Belt', orbiting: @star, orbit: 2, au: 1.0)
    companion = create_star('Beta', orbiting: @star, orbit: 3, au: 2.0)

    map = StarOrbitMap.new(@star.reload, link_builder: ->(object) { "/objects/#{object.id}" })
    hrefs = parse(map).css('a').map { |a| a['href'] }

    assert_equal [giant, belt, companion].map { |o| "/objects/#{o.id}" }.sort, hrefs.sort
    assert_equal %w[_top], parse(map).css('a').map { |a| a['target'] }.uniq
  end

  test 'names are escaped' do
    create_giant('<script>&"', 1)

    svg = StarOrbitMap.new(@star.reload).to_svg

    assert_not_includes svg, '<script>'
    assert_includes svg, '&lt;script&gt;&amp;&quot;'
  end

  test 'theme colours are baked into the svg' do
    create_giant('Giant', 1)
    palette = OrbitMapTheme.palette('aslan')

    svg = StarOrbitMap.new(@star.reload, theme: 'aslan').to_svg

    assert_includes svg, %(fill="#{palette.panel}")
    assert_includes svg, palette.highlight
    assert_includes svg, %(stroke="#{palette.outline}")
    assert_not_includes svg, 'var(--'
  end

  test 'inline images replaces image references with data uris' do
    create_giant('Giant', 1)

    plain = StarOrbitMap.new(@star.reload).to_svg
    inline = StarOrbitMap.new(@star, inline_images: true).to_svg

    assert_includes plain, 'href="/stellar_objects/'
    assert_not_includes inline, 'href="/stellar_objects/'
    assert_includes inline, 'href="data:image/webp;base64,'
  end

  test 'a star with a jump shadow gets a ring' do
    create_giant('Near', 1, au: 0.5)
    create_giant('Far', 3, au: 5.0)
    @star.update!(jump_shadow: 1.5 * StellarConstants::AU_TO_KM)

    ring = parse(StarOrbitMap.new(@star.reload)).at_css('circle[filter]')

    assert ring
    assert_equal '0.4', ring['opacity']
  end
end
