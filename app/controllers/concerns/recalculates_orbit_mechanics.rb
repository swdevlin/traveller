# frozen_string_literal: true

module RecalculatesOrbitMechanics
  extend ActiveSupport::Concern

  private

  def recalculate_orbit_mechanics_if_needed(object)
    return unless object.saved_change_to_eccentricity? || object.saved_change_to_inclination? || object.saved_change_to_orbit?

    star_system = object.star_system
    return unless star_system

    result = OrbitMechanicsRecalculator.new(star_system, generator_service).recalculate!
    flash[:alert] = "Field updated, but orbital positions could not be recalculated: #{result.errors.to_sentence}" unless result.success?
  rescue StandardError => e
    Rails.logger.error "OrbitMechanicsRecalculator failed: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    flash[:alert] = 'Field updated, but orbital positions could not be recalculated at this time.'
  end
end
