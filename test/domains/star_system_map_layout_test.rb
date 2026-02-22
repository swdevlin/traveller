# frozen_string_literal: true

require 'test_helper'

class StarSystemMapLayoutTest < ActiveSupport::TestCase
  setup do
    @parsec = parsecs(:one)
  end

  def create_system(name: 'Test System')
    StarSystem.create!(name: name, parsec: @parsec)
  end

  def create_star(star_system, name:, colour: 'Yellow', orbiting: nil, au: nil, orbit: nil)
    Star.create!(
      name: name,
      star_system: star_system,
      parsec: @parsec,
      colour: colour,
      stellar_type: 'G',
      stellar_subtype: 2,
      stellar_class: 'V',
      is_protostar: false,
      orbiting: orbiting,
      au: au,
      orbit: orbit
    )
  end

  def create_body(star, type:, name:, orbit:, au:)
    attrs = { name: name, orbiting_star: star, orbit: orbit, au: au }
    attrs.merge!(size_code: 5, atmosphere_code: 6, hydrographics_code: 3) if type == 'TerrestrialPlanet'
    type.constantize.create!(**attrs)
  end

  test 'single star with no bodies produces one node and no edges' do
    ss = create_system
    create_star(ss, name: 'Sol')

    layout = StarSystemMapLayout.new(ss)

    assert_equal 1, layout.nodes.size
    assert_equal :star, layout.nodes.first.kind
    assert_equal StarSystemMapLayout::LEFT_MARGIN, layout.nodes.first.x
    assert_equal StarSystemMapLayout::TOP_Y, layout.nodes.first.y
    assert_equal 0, layout.edges.size
  end

  test 'star with bodies creates track edge and body nodes' do
    ss = create_system
    star = create_star(ss, name: 'Sol')
    create_body(star, type: 'TerrestrialPlanet', name: 'Earth', orbit: 3, au: 1.0)
    create_body(star, type: 'GasGiant', name: 'Jupiter', orbit: 5, au: 5.2)
    create_body(star, type: 'PlanetoidBelt', name: 'Asteroid Belt', orbit: 4, au: 2.8)

    layout = StarSystemMapLayout.new(ss)

    star_nodes = layout.nodes.select { |n| n.kind == :star }
    body_nodes = layout.nodes.reject { |n| n.kind == :star }
    track_edges = layout.edges.select { |e| e.kind == :track }

    assert_equal 1, star_nodes.size
    assert_equal 3, body_nodes.size
    assert_equal 3, track_edges.size, 'One track edge per body segment'
  end

  test 'bodies are placed in orbit order with correct spacing' do
    ss = create_system
    star = create_star(ss, name: 'Sol')
    create_body(star, type: 'TerrestrialPlanet', name: 'Inner', orbit: 1, au: 0.5)
    create_body(star, type: 'TerrestrialPlanet', name: 'Outer', orbit: 5, au: 3.0)

    layout = StarSystemMapLayout.new(ss)

    lane_y = StarSystemMapLayout::TOP_Y
    bodies = layout.nodes.select { |n| n.y == lane_y && n.kind != :star }.sort_by(&:x)

    assert_equal 2, bodies.size
    expected_first_x = StarSystemMapLayout::LEFT_MARGIN + StarSystemMapLayout::STAR_TO_FIRST_BODY_GAP
    assert_equal expected_first_x, bodies[0].x
    assert_equal expected_first_x + StarSystemMapLayout::ORBIT_STEP, bodies[1].x
  end

  test 'body radii match type' do
    ss = create_system
    star = create_star(ss, name: 'Sol')
    create_body(star, type: 'TerrestrialPlanet', name: 'Earth', orbit: 1, au: 1.0)
    create_body(star, type: 'GasGiant', name: 'Jupiter', orbit: 2, au: 5.2)
    create_body(star, type: 'PlanetoidBelt', name: 'Belt', orbit: 3, au: 2.8)

    layout = StarSystemMapLayout.new(ss)

    terrestrial = layout.nodes.find { |n| n.kind == :terrestrial }
    gas_giant = layout.nodes.find { |n| n.kind == :gas_giant }
    belt = layout.nodes.find { |n| n.kind == :planetoid_belt }

    assert_equal StarSystemMapLayout::TERRESTRIAL_RADIUS, terrestrial.radius
    assert_equal StarSystemMapLayout::GAS_GIANT_RADIUS, gas_giant.radius
    assert_equal StarSystemMapLayout::PLANETOID_BELT_RADIUS, belt.radius
  end

  test 'companion star appears inline on the horizontal track' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    create_star(ss, name: 'Beta', orbiting: primary, au: 10.0, orbit: 8)

    layout = StarSystemMapLayout.new(ss)

    star_nodes = layout.nodes.select { |n| n.kind == :star }
    assert_equal 2, star_nodes.size

    primary_node = star_nodes.find { |n| n.label.include?('Alpha') }
    companion_node = star_nodes.find { |n| n.label.include?('Beta') }

    assert_equal StarSystemMapLayout::TOP_Y, primary_node.y
    assert_equal StarSystemMapLayout::TOP_Y, companion_node.y, 'Companion should be on same horizontal line'
    assert companion_node.x > primary_node.x, 'Companion should be to the right of primary'
  end

  test 'bodies orbiting companion drop vertically below it' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    companion = create_star(ss, name: 'Beta', orbiting: primary, au: 10.0, orbit: 5)
    create_body(companion, type: 'TerrestrialPlanet', name: 'Proxima b', orbit: 1, au: 0.1)
    create_body(companion, type: 'GasGiant', name: 'Proxima c', orbit: 3, au: 1.5)

    layout = StarSystemMapLayout.new(ss)

    companion_node = layout.nodes.find { |n| n.kind == :star && n.label.include?('Beta') }
    companion_x = companion_node.x

    vertical_bodies = layout.nodes.select { |n|
      n.x == companion_x && n.kind != :star
    }.sort_by(&:y)

    assert_equal 2, vertical_bodies.size
    assert_equal companion_x, vertical_bodies[0].x
    assert vertical_bodies[0].y > companion_node.y, 'Bodies should be below companion'

    step = StarSystemMapLayout::VERTICAL_STEP
    assert_equal companion_node.y + step, vertical_bodies[0].y
    assert_equal companion_node.y + 2 * step, vertical_bodies[1].y
  end

  test 'vertical branch edge connects companion to its last body' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    companion = create_star(ss, name: 'Beta', orbiting: primary, au: 10.0, orbit: 5)
    create_body(companion, type: 'TerrestrialPlanet', name: 'Planet', orbit: 1, au: 0.1)

    layout = StarSystemMapLayout.new(ss)

    branch_edges = layout.edges.select { |e| e.kind == :branch }
    assert_equal 1, branch_edges.size

    edge = branch_edges.first
    assert_equal edge.x1, edge.x2, 'Branch should be vertical'
    assert edge.y2 > edge.y1, 'Branch should go downward'
  end

  test 'three star hierarchy: tertiary drops below secondary' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    secondary = create_star(ss, name: 'Beta', orbiting: primary, au: 10.0, orbit: 5)
    tertiary = create_star(ss, name: 'Gamma', orbiting: secondary, au: 0.5, orbit: 2)

    layout = StarSystemMapLayout.new(ss)

    star_nodes = layout.nodes.select { |n| n.kind == :star }
    assert_equal 3, star_nodes.size

    alpha = star_nodes.find { |n| n.label.include?('Alpha') }
    beta = star_nodes.find { |n| n.label.include?('Beta') }
    gamma = star_nodes.find { |n| n.label.include?('Gamma') }

    # Alpha and Beta on same horizontal line
    assert_equal alpha.y, beta.y

    # Gamma drops below Beta vertically
    assert_equal beta.x, gamma.x
    assert_equal beta.y + StarSystemMapLayout::VERTICAL_STEP, gamma.y
  end

  test 'companion without bodies creates no branch edge' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    create_star(ss, name: 'Beta', orbiting: primary, au: 10.0, orbit: 5)

    layout = StarSystemMapLayout.new(ss)

    branch_edges = layout.edges.select { |e| e.kind == :branch }
    assert_equal 0, branch_edges.size
  end

  test 'svg dimensions accommodate all nodes' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    companion = create_star(ss, name: 'Beta', orbiting: primary, au: 10.0, orbit: 5)
    create_body(companion, type: 'GasGiant', name: 'Big Planet', orbit: 3, au: 5.0)

    layout = StarSystemMapLayout.new(ss)

    layout.nodes.each do |node|
      assert node.x < layout.svg_width, "Node #{node.id} x=#{node.x} exceeds svg_width=#{layout.svg_width}"
      assert node.y < layout.svg_height, "Node #{node.id} y=#{node.y} exceeds svg_height=#{layout.svg_height}"
    end
  end

  test 'star nodes reference Star objects and body nodes reference StellarObjects' do
    ss = create_system
    star = create_star(ss, name: 'Sol')
    create_body(star, type: 'TerrestrialPlanet', name: 'Earth', orbit: 1, au: 1.0)

    layout = StarSystemMapLayout.new(ss)

    star_nodes = layout.nodes.select { |n| n.kind == :star }
    body_nodes = layout.nodes.reject { |n| n.kind == :star }

    star_nodes.each { |n| assert_instance_of Star, n.url_target }
    body_nodes.each { |n| assert_kind_of StellarObject, n.url_target }
  end

  test 'body tooltip is nil (stub for future use)' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    companion = create_star(ss, name: 'Beta', orbiting: primary, au: 10.0, orbit: 5)
    create_body(companion, type: 'TerrestrialPlanet', name: 'Proxima b', orbit: 1, au: 0.1)

    layout = StarSystemMapLayout.new(ss)

    body_nodes = layout.nodes.select { |n| n.kind == :terrestrial }
    assert_equal 1, body_nodes.size
    assert_nil body_nodes.first.tooltip
  end

  test 'au labels on edges are formatted correctly' do
    ss = create_system
    star = create_star(ss, name: 'Sol')
    create_body(star, type: 'TerrestrialPlanet', name: 'Close', orbit: 1, au: 0.4)
    create_body(star, type: 'TerrestrialPlanet', name: 'Mid', orbit: 2, au: 0.7)
    create_body(star, type: 'GasGiant', name: 'Far', orbit: 3, au: 1.0)

    layout = StarSystemMapLayout.new(ss)

    track_edges = layout.edges.select { |e| e.kind == :track }.sort_by(&:x1)

    assert_equal '0.4', track_edges[0].au_label
    assert_equal '0.7', track_edges[1].au_label
    assert_equal '1.0', track_edges[2].au_label
  end

  test 'companion star edge shows au label' do
    ss = create_system
    primary = create_star(ss, name: 'Alpha')
    create_star(ss, name: 'Beta', orbiting: primary, orbit: 7)

    layout = StarSystemMapLayout.new(ss)

    track_edges = layout.edges.select { |e| e.kind == :track }
    assert_equal 1, track_edges.size
    assert_equal '10', track_edges.first.au_label
  end
end
