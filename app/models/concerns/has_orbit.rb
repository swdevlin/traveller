# frozen_string_literal: true

module HasOrbit
  extend ActiveSupport::Concern

  included do
    after_save_commit :reassign_orbit_sequences,
                      if: -> { !skip_import_callbacks && saved_change_to_orbit? }
    after_destroy_commit :reassign_orbit_sequences_after_destroy
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
