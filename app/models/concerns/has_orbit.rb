# frozen_string_literal: true

module HasOrbit
  extend ActiveSupport::Concern

  included do
    after_save_commit :reassign_orbit_sequences,
                      if: -> { !skip_import_callbacks && saved_change_to_orbit? }
    after_destroy_commit :reassign_orbit_sequences_after_destroy
  end

  # Systems generated before the generator started returning these won't have
  # them in `data`; fall back to computing from `au`/`eccentricity` for those.
  def periapsis
    data&.dig('periapsis') || au.to_f * (1 - eccentricity.to_f)
  end

  def apoapsis
    data&.dig('apoapsis') || au.to_f * (1 + eccentricity.to_f)
  end

  # `orbit_x`/`orbit_y` are the generator's actual position (already in km), absolute to the system's primary
  # star. This is the same position relative to the body being orbited (the primary star's own is the
  # origin), or nil when the position isn't known.
  def relative_orbit_position
    return nil unless orbit_x.present? && orbit_y.present?

    [orbit_x.to_f - orbiting&.orbit_x.to_f, orbit_y.to_f - orbiting&.orbit_y.to_f]
  end

  # Real distance from the immediate parent, in km. Prefers the generator's actual position over the nominal
  # `au` (semi-major axis) — with eccentric orbits the two can differ substantially, so anything computing a
  # body's current distance from its primary (e.g. jump shadow) needs the real position, not `au`.
  def orbit_distance_from_parent_km
    position = relative_orbit_position
    position ? Math.hypot(*position) : au.to_f * StellarConstants::AU_TO_KM
  end

  private

  def orbit_star_system
    raise NotImplementedError, "#{self.class}#orbit_star_system is not implemented"
  end

  def orbit_star_system_for_destroy
    raise NotImplementedError, "#{self.class}#orbit_star_system_for_destroy is not implemented"
  end

  def reassign_orbit_sequences
    system = orbit_star_system
    OrbitSequenceAssigner.new(system).assign! if system
  end

  def reassign_orbit_sequences_after_destroy
    system = orbit_star_system_for_destroy
    OrbitSequenceAssigner.new(system).assign! if system
  end
end
