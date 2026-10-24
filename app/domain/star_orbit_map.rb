# frozen_string_literal: true

require 'erb'

# Draws the orbit map for a single star as a standalone SVG: the star at the centre, with the
# objects orbiting it on concentric rings.
#
# A port of frontend/starmap/src/Traveller/StarOrbitMap.elm, so the Rails map matches the one in
# the starmap. The layout is rank-based rather than to scale: objects are spaced evenly from the
# star outwards in order of distance, with the real gaps between them nudging the spacing. Each
# object sits at its real bearing from the star.
#
# Differences from the Elm map:
# - Every object is drawn; the Elm map hides those the survey index hasn't revealed yet.
# - The canvas grows with the number of rings (see #canvas_size) so a crowded star stays legible.
# - Rings are scaled back into the canvas when the spacing nudges would carry them past the edge.
# - Child stars are linkable (the Elm map only links the planets).
# - Colours are baked in from the theme rather than resolved from CSS variables, so the SVG
#   works standalone and can be rasterised.
class StarOrbitMap
  include StellarObjectAppearance
  include OrbitEllipse

  # Bump when the drawing changes, to invalidate cached output.
  VERSION = 1

  STAR_RADIUS = 14
  GAS_GIANT_RADIUS = 10
  TERRESTRIAL_RADIUS = 8.05
  PLANETOID_BELT_RADIUS = 9
  PLANETOID_RADIUS = 4

  # Radius of the innermost ring, clear of the star.
  INNER_PX = STAR_RADIUS + 16
  # Gap kept between the outermost ring and the edge of the canvas: room for the largest object
  # plus the AU text beneath it. (The Elm map keeps 18px, which clips that text.)
  EDGE_MARGIN = GAS_GIANT_RADIUS + 18

  MIN_SIZE = 800
  # Target distance between neighbouring rings. Spacing can shrink to half of this where the
  # real gaps between orbits differ a lot (see GAP_ADJUSTMENT), which still leaves room for a
  # label.
  RING_SPACING_PX = 30

  GOLDEN_ANGLE = 2.399963
  # A gap between consecutive orbit numbers this many times the star's typical spacing marks the
  # objects beyond it as outliers (e.g. a distant companion), pinned to the outer ring.
  OUTLIER_GAP_MULTIPLIER = 4
  # Share of the ring band used by the core objects when there are outliers.
  CORE_BAND_FRACTION = 0.8
  # How far (as a fraction of a ring step) a real gap bigger or smaller than the previous one
  # can nudge an object outwards or inwards.
  GAP_ADJUSTMENT = 0.5
  # Planetoids belonging to a belt are scattered across this many pixels either side of the
  # belt's ring, according to how far their real distance differs from the belt's.
  PLANETOID_SPREAD_FRACTION = 0.2
  PLANETOID_SPREAD_PX = 14

  BODY_TYPES = %w[GasGiant TerrestrialPlanet PlanetoidBelt Planetoid].freeze

  Child = Struct.new(:object, :x_km, :y_km, :au, :orbit, :eccentricity, :synthetic_index) do
    # Real distance from the star, in AU.
    def au_dist
      r_km = Math.hypot(x_km, y_km)
      r_km.zero? ? [au, 0.01].max : r_km / StellarConstants::AU_TO_KM
    end
  end

  Placement = Struct.new(:child, :x, :y, :pixel_r)

  attr_reader :size, :placements

  # link_builder: callable taking an object (a Star or any other stellar object) and returning
  #   its URL, or nil for no link. With no builder the SVG has no links at all.
  # inline_images: embed the object images as data URIs, for an SVG served on its own.
  def initialize(star, theme: OrbitMapTheme::DEFAULT, link_builder: nil, inline_images: false)
    @star = star
    @palette = OrbitMapTheme.palette(theme)
    @link_builder = link_builder
    @inline_images = inline_images

    children = build_children
    belt_ids = children.filter_map { |c| c.object.id if c.object.type == 'PlanetoidBelt' }
    belt_bound, ranked = children.partition { |c| belt_id_of(c.object)&.in?(belt_ids) }
    @core, @outliers = partition_core_and_outliers(ranked)

    @size = canvas_size
    @center = @size / 2.0
    @outer_px = [INNER_PX, (@size / 2.0) - EDGE_MARGIN].max
    @core_outer_px = @outliers.empty? ? @outer_px : INNER_PX + (CORE_BAND_FRACTION * (@outer_px - INNER_PX))
    @sorted_core = @core.each_with_index.sort_by { |c, i| [c.au_dist, i] }.map(&:first)
    @core_positions = ranked_core_positions

    ranked_placements = @sorted_core.zip(@core_positions).map { |child, pixel_r| place(child, pixel_r) } +
                        @outliers.map { |child| place(child, @outer_px) }
    @placements = ranked_placements + place_belt_bound(belt_bound, ranked_placements)
  end

  def to_svg
    parts = [svg_open, defs, style]
    parts << %(<rect width="#{@size}" height="#{@size}" fill="#{@palette.panel}"/>)
    parts.concat(jump_shadow_rings)
    parts.concat(orbit_rings)
    parts << node_svg(centre_placement)
    parts.concat(@placements.map { |placement| node_svg(placement) })
    parts << '</svg>'

    svg = parts.join("\n")
    @inline_images ? SvgRasteriser.embed_images(svg) : svg
  end

  private

  # ── Children ────────────────────────────────────────────────────────────────

  # The star's companion followed by the other objects orbiting it, nearest first (the order the
  # starmap API returns them). Positions are taken relative to this star. Children whose position is unknown (0, 0) are fanned out by
  # golden angle, in that order.
  def build_children
    bodies = @star.stellar_objects.select { |o| BODY_TYPES.include?(o.type) }
    others = (bodies + @star.secondary_stars.to_a).each_with_index.sort_by { |o, i| [o.orbit.to_f, i] }.map(&:first)
    objects = [@star.companion].compact + others

    next_index = 0
    objects.map do |obj|
      # Positions are absolute to the primary star; the map is centred on this star.
      known = obj.orbit_x.to_f != 0 || obj.orbit_y.to_f != 0
      x_km = known ? obj.orbit_x.to_f - @star.orbit_x.to_f : 0.0
      y_km = known ? obj.orbit_y.to_f - @star.orbit_y.to_f : 0.0
      child = Child.new(obj, x_km, y_km, obj.au.to_f, obj.orbit.to_f, obj.eccentricity.to_f)
      unless known
        child.synthetic_index = next_index
        next_index += 1
      end
      child
    end
  end

  def belt_id_of(object)
    object.planetoid_belt_id.presence&.to_i if object.type == 'Planetoid'
  end

  # Splits children into a core cluster and far outliers, at the largest gap between consecutive
  # orbit numbers, if that gap is big enough. Returns [core, outliers], core sorted by orbit.
  def partition_core_and_outliers(ranked)
    sorted = ranked.each_with_index.sort_by { |c, i| [c.orbit, i] }.map(&:first)

    split = nil
    largest = nil
    sorted.each_cons(2).with_index do |(a, b), i|
      gap = b.orbit - a.orbit
      split, largest = i, gap if largest.nil? || gap > largest
    end

    return [sorted, []] unless split && largest > OUTLIER_GAP_MULTIPLIER * typical_orbit_gap

    [sorted.take(split + 1), sorted.drop(split + 1)]
  end

  # The star's usual spacing between adjacent orbit numbers, floored so a system with one or no
  # children can't collapse the outlier threshold to zero.
  def typical_orbit_gap
    [0.5, [@star.baseline.to_f, 1].max * @star.spread.to_f].max
  end

  # ── Layout ──────────────────────────────────────────────────────────────────

  # Rings are evenly ranked between the star and the outer edge, so the canvas has to grow with
  # the number of rings to keep them RING_SPACING_PX apart. When there are outliers the core
  # only gets CORE_BAND_FRACTION of the band.
  def canvas_size
    span = RING_SPACING_PX * (@core.size + 1)
    span /= CORE_BAND_FRACTION unless @outliers.empty?
    [MIN_SIZE, (2 * (INNER_PX + span + EDGE_MARGIN)).ceil].max
  end

  # Radius of each core ring (core sorted by real distance). Each step is the even spacing,
  # nudged by how much this object's real gap to its neighbour differs from the previous gap,
  # relative to the average gap. The nudge is capped at half a step so the order never inverts.
  def ranked_core_positions
    n = @sorted_core.size
    step = (@core_outer_px - INNER_PX) / (n + 1).to_f
    first = INNER_PX + step

    gaps = @sorted_core.map(&:au_dist).each_cons(2).map { |a, b| b - a }
    return Array.new(n, first) if gaps.empty?

    total = gaps.sum
    average_gap = total.zero? ? 1.0 : total / gaps.size

    previous_gap, *remaining_gaps = gaps
    position = first + step
    positions = [first, position]
    remaining_gaps.each do |gap|
      nudge = ((gap - previous_gap) / average_gap).clamp(-1, 1) * GAP_ADJUSTMENT * step
      position += step + nudge
      positions << position
      previous_gap = gap
    end
    fit_within_band(positions, @core_outer_px - step)
  end

  # Where each gap is bigger than the last (orbits usually spread out geometrically) the nudges
  # add up and can carry the outer rings past the edge of the canvas. Scale the rings back in so
  # the outermost sits at the limit; rings that already fit are left alone.
  def fit_within_band(positions, limit)
    last = positions.last
    return positions if last <= limit

    scale = (limit - INNER_PX) / (last - INNER_PX)
    positions.map { |position| INNER_PX + ((position - INNER_PX) * scale) }
  end

  def place(child, pixel_r)
    theta = child.synthetic_index ? child.synthetic_index * GOLDEN_ANGLE : Math.atan2(child.y_km, child.x_km)
    Placement.new(child, @center + (pixel_r * Math.cos(theta)), @center + (pixel_r * Math.sin(theta)), pixel_r)
  end

  # Planetoids of a belt on this map hug that belt's ring instead of taking a ring of their own.
  def place_belt_bound(belt_bound, ranked_placements)
    belt_bound.filter_map do |child|
      belt = ranked_placements.find { |p| p.child.object.id == belt_id_of(child.object) }
      next unless belt

      relative_offset = (child.au_dist - belt.child.au_dist) / [belt.child.au_dist, 0.01].max
      spread = (relative_offset / PLANETOID_SPREAD_FRACTION).clamp(-1, 1) * PLANETOID_SPREAD_PX
      place(child, [INNER_PX + 4, belt.pixel_r + spread].max)
    end
  end

  def centre_placement
    Placement.new(Child.new(@star, 0.0, 0.0, 0.0, 0.0, 0.0), @center, @center, 0)
  end

  # ── Jump shadows ────────────────────────────────────────────────────────────

  # Every star on the map gets a ring at its own position, all placed against the same
  # distance-to-radius scale from the core rings.
  def jump_shadow_rings
    stars = [centre_placement] + @placements.select { |p| p.child.object.type == 'Star' }
    stars.filter_map do |placement|
      radius = jump_shadow_radius(placement.child.object.jump_shadow)
      next unless radius

      %(<circle cx="#{n(placement.x)}" cy="#{n(placement.y)}" r="#{n(radius)}" fill="none" ) +
        %(stroke="#{star_fill_colour(placement.child.object)}" stroke-width="2" filter="url(#jump-glow)" opacity="0.4"/>)
    end
  end

  # The shadow's real distance falls between two rings: the boundary is drawn halfway between
  # their radii. Past the last ring it sits a little beyond it.
  def jump_shadow_radius(jump_shadow_km)
    return if jump_shadow_km.nil? || @sorted_core.empty?

    jump_au = jump_shadow_km.to_f / StellarConstants::AU_TO_KM
    anchors = [[0.0, 0.0]] + @sorted_core.map(&:au_dist).zip(@core_positions)
    inside = anchors.select { |au, _| au <= jump_au }.map(&:last).max
    outside = anchors.select { |au, _| au > jump_au }.map(&:last).min

    if inside && outside
      (inside + outside) / 2.0
    elsif inside
      [@core_outer_px, inside + 20].min
    end
  end

  # ── Orbit rings ─────────────────────────────────────────────────────────────

  def orbit_rings
    @placements.reject { |p| p.child.object.type == 'Planetoid' }.map { |placement| orbit_ring(placement) }
  end

  def orbit_ring(placement)
    child = placement.child
    theta = Math.atan2(placement.y - @center, placement.x - @center)
    ellipse = orbit_ellipse(theta, child.au_dist, [child.au, 0.01].max, child.eccentricity, placement.pixel_r)
    cx = @center + ellipse[:offset_x]
    cy = @center + ellipse[:offset_y]

    %(<ellipse cx="#{n(cx)}" cy="#{n(cy)}" rx="#{n(ellipse[:rx])}" ry="#{n(ellipse[:ry])}" ) +
      %(transform="rotate(#{n(ellipse[:rotation_deg])} #{n(cx)} #{n(cy)})" fill="none" ) +
      %(stroke="#{@palette.outline}" stroke-width="1" stroke-dasharray="2 3" opacity="0.85"/>)
  end

  # ── Nodes ───────────────────────────────────────────────────────────────────

  def node_svg(placement)
    object = placement.child.object
    planetoid = object.type == 'Planetoid'
    url = @link_builder && link_for(placement)

    content = [icon_svg(placement)]
    content.concat(label_svg(placement)) unless planetoid

    if url
      %(<a href="#{esc(url)}" target="_top" class="orbit-node">#{content.join}</a>)
    else
      %(<g>#{content.join}</g>)
    end
  end

  def link_for(placement)
    object = placement.child.object
    return if object.equal?(@star)

    @link_builder.call(object)
  end

  def icon_svg(placement)
    object = placement.child.object
    x = n(placement.x)
    y = n(placement.y)
    radius = radius_for(object)
    stroke = %(stroke="#{@palette.outline}" stroke-width="1.5")

    if object.type == 'Planetoid'
      return %(<ellipse cx="#{x}" cy="#{y}" rx="#{radius}" ry="#{n(radius * 0.6)}" transform="rotate(-20 #{x} #{y})" ) +
             %(fill="#{fill_for(object)}" #{stroke}/>)
    end

    image = image_for(object)
    if image
      %(<image href="/stellar_objects/#{image}.webp" x="#{n(placement.x - radius)}" y="#{n(placement.y - radius)}" ) +
        %(width="#{n(radius * 2)}" height="#{n(radius * 2)}" clip-path="url(#circle-clip)" preserveAspectRatio="xMidYMid slice"/>)
    else
      %(<circle cx="#{x}" cy="#{y}" r="#{radius}" fill="#{fill_for(object)}" #{stroke}/>)
    end
  end

  def label_svg(placement)
    object = placement.child.object
    radius = radius_for(object)
    label_y = n(placement.y - radius - 4)

    if object.type == 'Star'
      return [%(<text x="#{n(placement.x)}" y="#{label_y}" text-anchor="middle" class="sm-star-label">#{esc(star_label(object))}</text>)]
    end

    [
      %(<text x="#{n(placement.x)}" y="#{label_y}" text-anchor="middle" class="orbit-body-label">#{esc(body_label(object))}</text>),
      %(<text x="#{n(placement.x)}" y="#{n(placement.y + radius + 12)}" text-anchor="middle" class="orbit-au">#{format_au(placement.child.au_dist)}</text>)
    ]
  end

  def star_label(star)
    "#{star.stellar_type}#{star.stellar_subtype} #{star.stellar_class}".strip
  end

  def body_label(object)
    object.name.presence || object.orbit_sequence.to_s
  end

  def format_au(au)
    if au >= 10
      format('%.0f', au)
    elsif au >= 1
      format('%.1f', au)
    else
      format('%.2f', au)
    end
  end

  def radius_for(object)
    case object.type
    when 'Star' then STAR_RADIUS
    when 'GasGiant' then GAS_GIANT_RADIUS
    when 'TerrestrialPlanet' then TERRESTRIAL_RADIUS
    when 'PlanetoidBelt' then PLANETOID_BELT_RADIUS
    else PLANETOID_RADIUS
    end
  end

  def fill_for(object)
    case object.type
    when 'Star' then star_fill_colour(object)
    when 'GasGiant' then GAS_GIANT_COLOUR
    when 'PlanetoidBelt' then PLANETOID_BELT_COLOUR
    else terrestrial_colour(object)
    end
  end

  def image_for(object)
    case object.type
    when 'Star' then star_image(object)
    when 'GasGiant' then gas_giant_image(object)
    when 'TerrestrialPlanet' then terrestrial_image(object)
    when 'PlanetoidBelt' then :planetoid_belt
    end
  end

  # ── SVG framing ─────────────────────────────────────────────────────────────

  def svg_open
    %(<svg xmlns="http://www.w3.org/2000/svg" width="#{@size}" height="#{@size}" viewBox="0 0 #{@size} #{@size}" ) +
      %(style="max-width:100%;height:auto;display:block">)
  end

  def defs
    <<~SVG.chomp
      <defs>
        <clipPath id="circle-clip" clipPathUnits="objectBoundingBox"><circle cx="0.5" cy="0.5" r="0.5"/></clipPath>
        <filter id="jump-glow"><feGaussianBlur in="SourceGraphic" stdDeviation="2.5" result="blur"/><feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
      </defs>
    SVG
  end

  def style
    <<~SVG.chomp
      <style>
        .sm-star-label { font-family: "Tomorrow", system-ui, sans-serif; font-size: 12px; fill: #{@palette.highlight}; font-weight: 600; letter-spacing: 0.04em; }
        .orbit-body-label { font-family: ui-monospace, monospace; font-size: 11px; fill: #{@palette.highlight}; }
        .orbit-au { font-family: ui-monospace, monospace; font-size: 10px; fill: #{@palette.fg_muted}; }
        .orbit-node { cursor: pointer; }
        .orbit-node:hover circle, .orbit-node:hover image { opacity: 0.75; }
        a { text-decoration: none; }
      </style>
    SVG
  end

  def n(value)
    value.round(2)
  end

  def esc(text)
    ERB::Util.html_escape(text)
  end
end
