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

  # Real distance from the immediate parent, in km. Prefers the generator's
  # actual position (`orbit_x`/`orbit_y`, already in km) over the nominal
  # `au` (semi-major axis) — with eccentric orbits the two can differ
  # substantially, so anything computing a body's current distance from its
  # primary (e.g. jump shadow) needs the real position, not `au`.
  def orbit_distance_from_parent_km
    if orbit_x.present? && orbit_y.present?
      Math.sqrt((orbit_x.to_f**2) + (orbit_y.to_f**2))
    else
      au.to_f * StellarConstants::AU_TO_KM
    end
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
