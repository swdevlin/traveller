# frozen_string_literal: true

class StarSystemMapLayout
  LEFT_MARGIN = 80
  TOP_Y = 120
  ORBIT_STEP = 100
  STAR_TO_FIRST_BODY_GAP = 100
  VERTICAL_STEP = 100

  STAR_RADIUS = 26
  GAS_GIANT_RADIUS = 18
  TERRESTRIAL_RADIUS = 12
  PLANETOID_BELT_RADIUS = 18
  DEFAULT_BODY_RADIUS = 10

  Node = Struct.new(:id, :kind, :label, :x, :y, :radius, :colour, :url_target, :sublabel, :tooltip, keyword_init: true)
  Edge = Struct.new(:x1, :y1, :x2, :y2, :kind, :au_label, keyword_init: true)

  attr_reader :nodes, :edges, :svg_width, :svg_height

  def initialize(star_system)
    @star_system = star_system
    @nodes = []
    @edges = []
    @max_x = 0
    @max_y = 0
    compute_layout
  end

  private

  def compute_layout
    primary = @star_system.primary_star
    layout_primary(primary)
    calculate_dimensions
  end

  def layout_primary(star)
    star_x = LEFT_MARGIN
    star_y = TOP_Y

    @nodes << make_star_node(star, star_x, star_y)

    bodies = star.mapped_bodies
    current_x = star_x + STAR_TO_FIRST_BODY_GAP
    track_end_x = star_x
    prev_x = star_x

    bodies.each do |body|
      au_label = body.au.present? ? format_au(body.au) : nil
      @edges << Edge.new(x1: prev_x, y1: star_y, x2: current_x, y2: star_y, kind: :track, au_label: au_label)

      if body.is_a?(Star)
        @nodes << make_star_node(body, current_x, star_y)
        layout_vertical_branch(body, current_x, star_y)
      else
        @nodes << make_body_node(body, current_x, star_y, star, primary: true)
      end
      track_end_x = current_x
      prev_x = current_x
      current_x += ORBIT_STEP
    end

    @max_x = [@max_x, current_x].max
  end

  def layout_vertical_branch(star, x, parent_y)
    bodies = star.mapped_bodies
    return if bodies.empty?

    current_y = parent_y + VERTICAL_STEP
    branch_end_y = parent_y
    prev_y = parent_y

    bodies.each do |body|
      au_label = body.au.present? ? format_au(body.au) : nil
      @edges << Edge.new(x1: x, y1: prev_y, x2: x, y2: current_y, kind: :branch, au_label: au_label)

      if body.is_a?(Star)
        @nodes << make_star_node(body, x, current_y)
        layout_vertical_branch(body, x, current_y)
      else
        @nodes << make_body_node(body, x, current_y, star, primary: false)
      end
      branch_end_y = current_y
      prev_y = current_y
      current_y += VERTICAL_STEP
    end

    @max_y = [@max_y, current_y].max
  end

  def calculate_dimensions
    right_padding = 80
    bottom_padding = 80
    @svg_width = [@max_x + right_padding, LEFT_MARGIN + STAR_TO_FIRST_BODY_GAP + right_padding].max
    @svg_height = [@max_y + bottom_padding, TOP_Y + bottom_padding].max
  end

  def make_star_node(star, x, y)
    Node.new(
      id: "star-#{star.id}",
      kind: :star,
      label: star.display_name,
      x: x,
      y: y,
      radius: STAR_RADIUS,
      colour: star.colour,
      url_target: star,
      sublabel: nil,
      tooltip: star.display_name
    )
  end

  def make_body_node(body, x, y, parent_star, primary:)
    Node.new(
      id: "body-#{body.id}",
      kind: body_kind(body),
      label: body.name.presence,
      x: x,
      y: y,
      radius: radius_for(body),
      colour: body.is_a?(TerrestrialPlanet) ? terrestrial_colour(body) : nil,
      url_target: body,
      sublabel: body_sublabel(body),
      tooltip: body_tooltip(body, parent_star, primary)
    )
  end

  def body_kind(body)
    case body
    when GasGiant then :gas_giant
    when TerrestrialPlanet then :terrestrial
    when PlanetoidBelt then :planetoid_belt
    else :other
    end
  end

  def radius_for(body)
    case body
    when GasGiant then GAS_GIANT_RADIUS
    when TerrestrialPlanet then TERRESTRIAL_RADIUS
    when PlanetoidBelt then PLANETOID_BELT_RADIUS
    else DEFAULT_BODY_RADIUS
    end
  end

  def format_au(au_value)
    if au_value >= 10
      "#{au_value.round}"
    elsif au_value >= 1
      "#{au_value.round(1)}"
    else
      "#{au_value.round(2)}"
    end
  end

  def body_sublabel(body)
    case body
    when TerrestrialPlanet
      body.uwp.presence
    when GasGiant
      body.code.presence
    when PlanetoidBelt
      bodies = body.significant_bodies
      bodies.present? && bodies.size > 0 ? "#{bodies.size} bodies" : nil
    end
  end

  def terrestrial_colour(body)
    atmo_code = body.atmosphere&.dig('code') || 0
    hydro_code = body.hydrographics&.dig('code') || 0

    # Exotic/hostile atmospheres
    return '#16a34a' if atmo_code == 10 # exotic — green
    return '#f59e0b' if atmo_code == 11 # corrosive — amber
    return '#ef4444' if atmo_code == 12 # insidious — red

    # No atmosphere: airless rock
    return '#78716c' if atmo_code == 0

    # Has atmosphere, increasing water coverage
    return '#d97706' if hydro_code == 0
    return '#b45309' if hydro_code <= 2
    return '#0e7490' if hydro_code <= 4
    return '#0369a1' if hydro_code <= 6
    return '#1d4ed8' if hydro_code <= 8
    '#1e40af' # water world
  end

  def body_tooltip(body, parent_star, is_primary)
    # if is_primary
    #   "#{format_au(body.au)} from #{parent_star.display_name}"
    # end
    # parts = [body.display_name, "(#{body.type_title})"]
    # parts << "- #{format_au(body.au)}" if body.au.present?
    # parts << "from #{parent_star.display_name}" unless is_primary
    # parts.join(' ')
  end
end
