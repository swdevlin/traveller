# frozen_string_literal: true

# Moves every body in a star system along its orbit by a number of days. A body travels through its own period
# (`period`, days), so a body with no period, no position or no orbit is skipped. Bodies move anticlockwise unless
# they are retrograde: either flagged so, or (as the generator gives for moons) with a negative period. A negative
# number of days rewinds.
#
# The point on the orbit is worked out from the stored position (`orbit_x`/`orbit_y`) and the longitude of
# periapsis in the body's `data` (`longitude_of_periapsis`, degrees), which the generator supplies. A body without
# one (generated before it was supplied) has it recovered from its position the way `OrbitEllipse` does, taking
# the body to be on the outbound half of its orbit, and stored, so that later advances and the orbit maps agree.
class OrbitAdvancer < OrbitPositionRecomputer
  MAX_ECCENTRICITY = 0.95
  TWO_PI = Math::PI * 2

  def initialize(star_system, days:)
    super(star_system)
    @days = days
    @periapsis_directions = {}
  end

  private

  def calculate(body, parent, star)
    centre = body.is_a?(Moon) ? parent : star
    signed_period = body.respond_to?(:period) ? body.period.to_f : 0.0
    period = signed_period.abs
    semi_major_axis = semi_major_axis_km(body, parent)
    return unless period.positive? && semi_major_axis&.positive? && body.orbit_x.present? && body.orbit_y.present?

    dx = body.orbit_x.to_f - centre.orbit_x.to_f
    dy = body.orbit_y.to_f - centre.orbit_y.to_f
    # The generator gives companion stars no position, so they are stored on top of their parent. The orbit maps
    # draw such a body at bearing 0, a semi-major axis out, so start it there: its orbit line is then unchanged.
    dx, dy = semi_major_axis, 0.0 if dx.zero? && dy.zero?

    eccentricity = body.eccentricity.to_f.clamp(0, MAX_ECCENTRICITY)
    direction = body.longitude_of_periapsis_radians ||
                recovered_periapsis_direction(dx, dy, semi_major_axis, eccentricity)
    mean_anomaly = mean_anomaly_at(Math.atan2(dy, dx) - direction, eccentricity)
    retrograde = signed_period.negative? || body.try(:retrograde)
    travelled = TWO_PI * @days / period * (retrograde ? -1 : 1)

    calculator = OrbitPositionCalculator.new(semi_major_axis: semi_major_axis, eccentricity: eccentricity,
                                             centre_x: @positions[centre.id][0], centre_y: @positions[centre.id][1],
                                             periapsis_direction: direction, mean_anomaly: (mean_anomaly + travelled) % TWO_PI)
    @periapsis_directions[body.id] = direction
    [calculator.x, calculator.y]
  end

  def recovered_periapsis_direction(dx, dy, semi_major_axis, eccentricity)
    theta = Math.atan2(dy, dx)
    return theta unless eccentricity > 1.0e-6

    cos_nu = (((semi_major_axis * (1 - (eccentricity**2))) / Math.hypot(dx, dy) - 1) / eccentricity).clamp(-1, 1)
    theta - Math.acos(cos_nu)
  end

  # The mean anomaly of a body whose true anomaly is `true_anomaly`.
  def mean_anomaly_at(true_anomaly, eccentricity)
    eccentric = 2 * Math.atan2(Math.sqrt(1 - eccentricity) * Math.sin(true_anomaly / 2),
                               Math.sqrt(1 + eccentricity) * Math.cos(true_anomaly / 2))
    eccentric - (eccentricity * Math.sin(eccentric))
  end

  def write_changes
    StellarObject.transaction do
      @changes.each do |change|
        body = change.body
        degrees = (@periapsis_directions[body.id] * 180 / Math::PI) % 360
        data = (body.data || {}).merge('longitude_of_periapsis' => degrees)
        body.update_columns(orbit_x: change.to[0], orbit_y: change.to[1], data: data)
      end
      @star_system.add_elapsed_days!(@days)
    end
  end
end
