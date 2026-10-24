# frozen_string_literal: true

# Recovers the ellipse an orbit map draws for a body from its real position, for the orbit maps
# that place bodies on rank-based rings rather than to scale.
module OrbitEllipse
  # Caps how far an orbit ellipse can stretch beyond the object's own ring radius.
  MAX_ORBIT_STRETCH = 3

  private

  # The orbit's ellipse, recovered from the object's real position (bearing theta, distance r),
  # semi-major axis a and eccentricity e. The generator keeps only the resulting position, not
  # the direction of periapsis, so that is recovered from the orbit's polar equation. The
  # ellipse is then scaled to put the object exactly on its ring.
  def orbit_ellipse(theta, r, a, e, pixel_r)
    ecc = e.clamp(0, 0.95)
    cos_nu = ecc > 1.0e-6 ? (((a * (1 - (ecc**2))) / r - 1) / ecc).clamp(-1, 1) : 1
    periapsis_dir = theta - Math.acos(cos_nu)

    a_px = [pixel_r * (1 + (ecc * cos_nu)) / (1 - (ecc**2)), MAX_ORBIT_STRETCH * pixel_r].min
    b_px = a_px * Math.sqrt(1 - (ecc**2))
    c_px = a_px * ecc

    {
      rx: a_px,
      ry: b_px,
      rotation_deg: periapsis_dir * 180 / Math::PI,
      offset_x: -c_px * Math.cos(periapsis_dir),
      offset_y: -c_px * Math.sin(periapsis_dir),
      reach: a_px + c_px
    }
  end
  # As orbit_ellipse, but the semi-major axis is fixed at a_px (the body's rank ring) and the
  # object is placed where its real distance r puts it on that ellipse, so it always lies on
  # the drawn orbit. Adds the object's pixel distance from the focus as :r_px.
  def ranked_orbit_ellipse(theta, r, a, e, a_px)
    ecc = e.clamp(0, 0.95)
    cos_nu = ecc > 1.0e-6 ? (((a * (1 - (ecc**2))) / r - 1) / ecc).clamp(-1, 1) : 1
    periapsis_dir = theta - Math.acos(cos_nu)
    c_px = a_px * ecc

    {
      rx: a_px,
      ry: a_px * Math.sqrt(1 - (ecc**2)),
      rotation_deg: periapsis_dir * 180 / Math::PI,
      offset_x: -c_px * Math.cos(periapsis_dir),
      offset_y: -c_px * Math.sin(periapsis_dir),
      reach: a_px + c_px,
      r_px: a_px * (1 - (ecc**2)) / (1 + (ecc * cos_nu))
    }
  end
end
