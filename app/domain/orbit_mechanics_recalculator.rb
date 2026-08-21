# frozen_string_literal: true

# Calls the generator service's POST /orbit_mechanics endpoint with the
# current state of a star system, then writes the recalculated orbit
# positions (and defensively, eccentricity/inclination) back onto every
# matched body. Triggered after a user edits eccentricity/inclination on a
# star or stellar object.
class OrbitMechanicsRecalculator
  Result = Struct.new(:errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end

  def initialize(star_system, generator_service)
    @star_system = star_system
    @generator_service = generator_service
  end

  def recalculate!
    payload = OrbitMechanicsSerializer.new(@star_system).serialize
    result = @generator_service.compute_orbit_mechanics(payload)
    return Result.new(errors: result.errors) unless result.success?

    tree = result.value['primaryStar']
    unless tree.is_a?(Hash)
      Rails.logger.error("OrbitMechanicsRecalculator: unexpected response shape: #{result.value.inspect}")
      return Result.new(errors: ['Generator service returned an unexpected response'])
    end

    apply!(tree)
    Result.new(errors: [])
  end

  private

  def apply!(tree)
    objects_by_orbit_seq = StellarObject
      .where(star_system_id: @star_system.id)
      .index_by(&:orbit_sequence)

    ActiveRecord::Base.transaction do
      walk(tree, objects_by_orbit_seq, is_primary: true)
    end
  end

  def walk(node, objects_by_orbit_seq, is_primary: false)
    apply_node(node, objects_by_orbit_seq) unless is_primary

    Array(node['stellarObjects']).each { |child| walk(child, objects_by_orbit_seq) }
    Array(node['moons']).each { |moon_node| apply_node(moon_node, objects_by_orbit_seq) }
  end

  def apply_node(node, objects_by_orbit_seq)
    orbit_seq = node['orbitSequence']
    if orbit_seq.blank?
      Rails.logger.warn("OrbitMechanicsRecalculator: response node missing orbitSequence, skipping: #{node.inspect}")
      return
    end

    record = objects_by_orbit_seq[orbit_seq]
    unless record
      Rails.logger.warn("OrbitMechanicsRecalculator: no local record for orbitSequence=#{orbit_seq.inspect}, skipping")
      return
    end

    position = node['orbitPosition'] || {}
    record.update_columns(
      orbit_x: position['x'],
      orbit_y: position['y'],
      eccentricity: node.fetch('eccentricity', record.eccentricity),
      inclination: node.fetch('inclination', record.inclination)
    )
  end
end
