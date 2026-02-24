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
  JumpShadow = Struct.new(:x, :y, :x1, :x2, :vertical, :y1_branch, :y2_branch, :colour, :has_marker, keyword_init: true)

  attr_reader :nodes, :edges, :jump_shadows, :svg_width, :svg_height

  def initialize(star_system)
    @star_system = star_system
    @nodes = []
    @edges = []
    @jump_shadows = []
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
    track_end_x = star_x

    # Compute primary jump shadow before the main loop so companion branches
    # receive the correct primary_jump_x during their layout.
    primary_jump_x = compute_jump_x(star, star_x, bodies)

    current_x = star_x + STAR_TO_FIRST_BODY_GAP
    prev_x = star_x

    bodies.each do |body|
      au_label = body.au.present? ? format_au(body.au) : nil
      @edges << Edge.new(x1: prev_x, y1: star_y, x2: current_x, y2: star_y, kind: :track, au_label: au_label)

      if body.is_a?(Star)
        @nodes << make_star_node(body, current_x, star_y)
        layout_vertical_branch(body, current_x, star_y, primary_jump_x: primary_jump_x)
      else
        @nodes << make_body_node(body, current_x, star_y, star, primary: true)
      end
      track_end_x = current_x
      prev_x = current_x
      current_x += ORBIT_STEP
    end

    @max_x = [@max_x, current_x].max

    if primary_jump_x
      @jump_shadows << JumpShadow.new(
        x: primary_jump_x, y: star_y,
        x1: star_x, x2: track_end_x,
        vertical: false, colour: star.colour, has_marker: true
      )
    end
  end

  def layout_vertical_branch(star, x, parent_y, primary_jump_x: nil)
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
        layout_vertical_branch(body, x, current_y, primary_jump_x: primary_jump_x)
      else
        @nodes << make_body_node(body, x, current_y, star, primary: false)
      end
      branch_end_y = current_y
      prev_y = current_y
      current_y += VERTICAL_STEP
    end

    @max_y = [@max_y, current_y].max

    # Secondary star's own jump shadow on its vertical branch
    jump_y = compute_jump_y(star, parent_y, bodies)
    if jump_y
      @jump_shadows << JumpShadow.new(
        vertical: true, has_marker: true,
        x: x, y1_branch: parent_y, y2_branch: jump_y,
        colour: star.colour
      )
    end

    # Entire branch within primary's shadow (no extra marker — the primary's
    # horizontal marker already shows the boundary)
    if primary_jump_x && x <= primary_jump_x && branch_end_y > parent_y
      @jump_shadows << JumpShadow.new(
        vertical: true, has_marker: false,
        x: x, y1_branch: parent_y, y2_branch: branch_end_y,
        colour: star.colour
      )
    end
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

  # Vertical equivalent of compute_jump_x — returns the boundary pixel y for
  # a star's jump shadow on its vertical branch, or nil if not applicable.
  def compute_jump_y(star, parent_y, bodies)
    return nil unless star.jump_shadow.present?
    return nil if bodies.empty?

    jump_au = star.jump_shadow.to_f / StellarConstants::AU_TO_KM

    anchors = []
    bodies.each_with_index do |body, i|
      next unless body.au.present?

      anchors << [body.au.to_f, (parent_y + VERTICAL_STEP + i * VERTICAL_STEP).to_f]
    end
    return nil if anchors.empty?

    anchors.unshift([0.0, parent_y.to_f])

    inside_y  = anchors.select { |(au, _)| au <= jump_au }.last&.last
    outside_y = anchors.select { |(au, _)| au > jump_au  }.first&.last

    if inside_y && outside_y
      (inside_y + outside_y) / 2.0
    elsif inside_y
      inside_y + VERTICAL_STEP / 2.0
    else
      (parent_y + anchors[1][1]) / 2.0
    end
  end

  # Returns the jump shadow boundary pixel x for the given star, or nil if
  # the star has no jump_shadow data or no bodies to anchor the scale.
  #
  # The boundary is placed at the midpoint between the last body inside the
  # shadow and the first body outside it (subway-style, not to scale).
  def compute_jump_x(star, star_x, bodies)
    return nil unless star.jump_shadow.present?
    return nil if bodies.empty?

    jump_au = star.jump_shadow.to_f / StellarConstants::AU_TO_KM

    # Build (au, pixel_x) pairs for bodies that have AU values.
    anchors = []
    bodies.each_with_index do |body, i|
      next unless body.au.present?

      anchors << [body.au.to_f, (star_x + STAR_TO_FIRST_BODY_GAP + i * ORBIT_STEP).to_f]
    end
    return nil if anchors.empty?

    # Prepend the star itself as the leftmost anchor.
    anchors.unshift([0.0, star_x.to_f])

    # Find the midpoint between the last anchor inside the shadow and the
    # first anchor outside it.
    inside_x  = anchors.select { |(au, _)| au <= jump_au }.last&.last
    outside_x = anchors.select { |(au, _)| au > jump_au  }.first&.last

    if inside_x && outside_x
      (inside_x + outside_x) / 2.0
    elsif inside_x
      # All bodies inside: place tick half a step after the last body.
      inside_x + ORBIT_STEP / 2.0
    else
      # All bodies outside: place tick halfway between star and first body.
      (star_x + anchors[1][1]) / 2.0
    end
  end
end
