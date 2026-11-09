# frozen_string_literal: true

# Recomputes the stored orbit position (`orbit_x`/`orbit_y`, km, absolute to the primary star) of every body in a
# star system, for systems whose positions can't be trusted (older generations offset bodies around a secondary
# star from the primary star instead of from the star they orbit).
#
# Each body is placed on a random point of its own orbit, centred on its corrected parent, exactly as when a body
# is added in the UI. The primary star is the origin. Moons orbit their planet; everything else is centred on the
# nearest star above it (so planetoids sit on their belt's star, as `PlanetoidsController` does). Because the
# angles are drawn afresh, every body ends up somewhere different on its orbit. Semi-major axes and eccentricities are kept, so a body's
# distance from its parent stays between its periapsis and apoapsis, but is not the same as before. A moon's orbit
# is in diameters of its planet.
class OrbitPositionRecomputer
  Change = Struct.new(:body, :from, :to, keyword_init: true)

  attr_reader :changes, :skipped

  def initialize(star_system, random: Random.new)
    @star_system = star_system
    @random = random
    @changes = []
    @skipped = []
  end

  # @param apply [Boolean] write the new positions; otherwise only compute them
  def call(apply: true)
    objects = (@star_system.stars.to_a + @star_system.stellar_objects.to_a).uniq(&:id)
    primary = objects.find { |o| o.is_a?(Star) && o.orbiting_id.nil? }
    return self unless primary

    @children = objects.select(&:orbiting_id).group_by(&:orbiting_id)
    @positions = { primary.id => [0.0, 0.0] }
    place_children(primary, primary)
    write_changes if apply
    self
  end

  private

  # `star` is the nearest star at or above `parent`.
  def place_children(parent, star)
    Array(@children[parent.id]).each do |body|
      next if body.is_a?(Ring)

      position = calculate(body, parent, star)
      if position
        @positions[body.id] = position
        record(body, position)
      else
        @skipped << body
        @positions[body.id] = [body.orbit_x.to_f, body.orbit_y.to_f]
      end
      place_children(body, body.is_a?(Star) ? body : star)
    end
  end

  def calculate(body, parent, star)
    centre = body.is_a?(Moon) ? parent : star
    centre_x, centre_y = @positions[centre.id]
    semi_major_axis = semi_major_axis_km(body, parent)
    return unless semi_major_axis&.positive?

    calculator = OrbitPositionCalculator.new(semi_major_axis: semi_major_axis, eccentricity: body.eccentricity,
                                             centre_x: centre_x, centre_y: centre_y, random: @random)
    [calculator.x, calculator.y]
  end

  def semi_major_axis_km(body, parent)
    if body.is_a?(Moon)
      body.orbit.to_f * parent.diameter.to_f if body.orbit.present? && parent.diameter.present?
    elsif body.orbit.present?
      OrbitToAu.convert(body.orbit) * StellarConstants::AU_TO_KM
    elsif body.au.present?
      body.au.to_f * StellarConstants::AU_TO_KM
    end
  end

  def record(body, position)
    @changes << Change.new(body: body, from: [body.orbit_x.to_f, body.orbit_y.to_f], to: position)
  end

  def write_changes
    StellarObject.transaction do
      @changes.each { |change| change.body.update_columns(orbit_x: change.to[0], orbit_y: change.to[1]) }
    end
  end
end
