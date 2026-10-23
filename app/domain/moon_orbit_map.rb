# frozen_string_literal: true

require 'erb'

# Draws the orbit map for a planet's moons as a standalone SVG: the planet at the centre, with
# its moons on concentric rings and its rings as translucent bands.
#
# Like StarOrbitMap the layout is rank-based rather than to scale: moons are spaced evenly
# outwards in order of distance, as a gas giant's outer moons can lie hundreds of planetary
# diameters out. Moon bearings are not recorded, so moons are fanned out by golden angle.
# The map is drawn large enough to show each moon in detail, so the canvas grows with the number
# of moons rather than the moons shrinking to fit. A ring's inner and outer edges are placed by interpolating between the moons either side.
class MoonOrbitMap
  include MoonMapAppearance

  # Bump when the drawing changes, to invalidate cached output.
  VERSION = 2

  PLANET_RADIUS = 36
  ORBIT_MIN_MOON_RADIUS = 10
  ORBIT_MAX_MOON_RADIUS = 26
  INNER_PX = PLANET_RADIUS + 44
  # Room for the largest moon plus its labels beyond the outermost ring.
  EDGE_MARGIN = ORBIT_MAX_MOON_RADIUS + 36
  # Rough width of a character in the planet's name, to size the canvas to it when there are few moons.
  PLANET_LABEL_CHAR_PX = 10
  # Large enough that neighbouring rings clear the largest moon and its labels.
  RING_SPACING_PX = 72
  GOLDEN_ANGLE = 2.399963

  Placement = Struct.new(:body, :x, :y, :pixel_r)

  attr_reader :size, :placements

  # link_builder: callable taking a moon and returning its URL, or nil for no link.
  # inline_images: embed the object images as data URIs, for an SVG served or rasterised on its own.
  def initialize(planet, significant_only: false, theme: OrbitMapTheme::DEFAULT, link_builder: nil, inline_images: false)
    @planet = planet
    @palette = OrbitMapTheme.palette(theme)
    @link_builder = link_builder
    @inline_images = inline_images

    bodies = map_bodies(planet, significant_only)
    @rings, @moons = bodies.partition { |body| ring?(body) }

    # The outermost ring sits one margin in from the edge, so the canvas fits the rings snugly.
    @step = RING_SPACING_PX
    rings_half = INNER_PX + (@step * [@moons.size - 1, 0].max) + EDGE_MARGIN
    label_half = (@planet.display_name.to_s.length * PLANET_LABEL_CHAR_PX / 2.0) + 8
    @size = (2 * [rings_half, label_half].max).ceil
    @center = @size / 2.0
    @placements = @moons.each_with_index.map { |moon, i| place(moon, i) }
  end

  def to_svg
    parts = [svg_open, defs, style]
    parts << %(<rect width="#{@size}" height="#{@size}" fill="#{@palette.panel}"/>)
    parts.concat(@rings.map { |ring| ring_band(ring) })
    parts.concat(@placements.map { |placement| orbit_ring(placement) })
    parts << planet_svg
    parts.concat(@placements.map { |placement| moon_svg(placement) })
    parts << '</svg>'

    svg = parts.join("\n")
    @inline_images ? SvgRasteriser.embed_images(svg) : svg
  end

  private

  def place(moon, index)
    pixel_r = INNER_PX + (@step * index)
    theta = index * GOLDEN_ANGLE
    Placement.new(moon, @center + (pixel_r * Math.cos(theta)), @center + (pixel_r * Math.sin(theta)), pixel_r)
  end

  # Pixel radius for a distance in planetary diameters, interpolated between the moons' rings.
  # The planet's surface (half a diameter) anchors the inside, and distances past the last moon
  # continue at the last gap's rate.
  def pixel_for(distance)
    anchors = [[0.5, PLANET_RADIUS + 4.0]] + @placements.map { |p| [p.body.orbit.to_f, p.pixel_r] }
    anchors = anchors.uniq(&:first).sort_by(&:first)
    return anchors.first.last if anchors.size < 2

    lower, upper = anchors.each_cons(2).find { |_, b| distance <= b.first } || anchors.last(2)
    run = upper.first - lower.first
    fraction = run.zero? ? 0 : (distance - lower.first) / run
    lower.last + (fraction * (upper.last - lower.last))
  end

  def ring_band(ring)
    inner = [pixel_for(ring.inner_edge), PLANET_RADIUS + 2].max
    outer = [pixel_for(ring.outer_edge), inner + 3].max
    mid = (inner + outer) / 2.0
    %(<circle cx="#{n(@center)}" cy="#{n(@center)}" r="#{n(mid)}" fill="none" stroke="#{@palette.fg_muted}" ) +
      %(stroke-width="#{n(outer - inner)}" opacity="0.3"><title>#{esc(body_label(ring))}</title></circle>)
  end

  def orbit_ring(placement)
    %(<circle cx="#{n(@center)}" cy="#{n(@center)}" r="#{n(placement.pixel_r)}" fill="none" ) +
      %(stroke="#{@palette.outline}" stroke-width="1" stroke-dasharray="2 3" opacity="0.85"/>)
  end

  def planet_svg
    image = planet_image(@planet)
    icon = if image
      %(<image href="/stellar_objects/#{image}.webp" x="#{n(@center - PLANET_RADIUS)}" y="#{n(@center - PLANET_RADIUS)}" ) +
        %(width="#{PLANET_RADIUS * 2}" height="#{PLANET_RADIUS * 2}" clip-path="url(#circle-clip)" preserveAspectRatio="xMidYMid slice"/>)
    else
      %(<circle cx="#{n(@center)}" cy="#{n(@center)}" r="#{PLANET_RADIUS}" fill="#{planet_fill(@planet)}" ) +
        %(stroke="#{@palette.outline}" stroke-width="1.5"/>)
    end
    label = %(<text x="#{n(@center)}" y="#{n(@center - PLANET_RADIUS - 8)}" text-anchor="middle" class="mm-planet-label">) +
            %(#{esc(@planet.display_name)}</text>)
    "<g>#{icon}#{label}</g>"
  end

  def moon_svg(placement)
    moon = placement.body
    radius = orbit_moon_radius(moon)
    x = n(placement.x)
    y = n(placement.y)
    image = moon_image(moon)
    icon = if image
      %(<image href="/stellar_objects/#{image}.webp" x="#{n(placement.x - radius)}" y="#{n(placement.y - radius)}" ) +
        %(width="#{n(radius * 2)}" height="#{n(radius * 2)}" clip-path="url(#circle-clip)" preserveAspectRatio="xMidYMid slice"/>)
    else
      %(<circle cx="#{x}" cy="#{y}" r="#{n(radius)}" fill="#{moon_fill(moon)}" stroke="#{@palette.outline}" stroke-width="1.5"/>)
    end
    content = icon +
              %(<text x="#{x}" y="#{n(placement.y - radius - 6)}" text-anchor="middle" class="mm-label">#{esc(body_label(moon))}</text>) +
              %(<text x="#{x}" y="#{n(placement.y + radius + 16)}" text-anchor="middle" class="mm-orbit">#{format_orbit(moon.orbit)}</text>)

    url = @link_builder&.call(moon)
    url ? %(<a href="#{esc(url)}" target="_top" class="mm-node">#{content}</a>) : "<g>#{content}</g>"
  end

  def orbit_moon_radius(moon)
    moon_radius(moon, min: ORBIT_MIN_MOON_RADIUS, max: ORBIT_MAX_MOON_RADIUS)
  end

  def svg_open
    %(<svg xmlns="http://www.w3.org/2000/svg" width="#{@size}" height="#{@size}" viewBox="0 0 #{@size} #{@size}" ) +
      %(style="max-width:100%;height:auto;display:block">)
  end

  def defs
    '<defs><clipPath id="circle-clip" clipPathUnits="objectBoundingBox"><circle cx="0.5" cy="0.5" r="0.5"/></clipPath></defs>'
  end

  def style
    <<~SVG.chomp
      <style>
        .mm-planet-label { font-family: "Tomorrow", system-ui, sans-serif; font-size: 15px; fill: #{@palette.highlight}; font-weight: 600; letter-spacing: 0.04em; }
        .mm-label { font-family: ui-monospace, monospace; font-size: 13px; fill: #{@palette.highlight}; }
        .mm-orbit { font-family: ui-monospace, monospace; font-size: 12px; fill: #{@palette.fg_muted}; }
        .mm-node { cursor: pointer; }
        .mm-node:hover circle, .mm-node:hover image { opacity: 0.75; }
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
