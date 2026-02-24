# frozen_string_literal: true

class OrbitSequenceAssigner
  def initialize(star_system)
    @star_system = star_system
    @letter_index = 0
  end

  def assign!
    primary = @star_system.stars.reload.find_by(orbiting: nil)
    return unless primary

    assign_star(primary, '')
    assign_planetoid_objects(primary)
  end

  private

  def next_letter
    @letter_index += 1
    (64 + @letter_index).chr
  end

  def assign_star(star, orbiting_prefix)
    letter = next_letter
    star.update_column(:orbit_sequence, letter)

    if star.companion_id.present?
      star.companion.update_column(:orbit_sequence, letter + 'b')
    end

    orbiting = orbiting_prefix + letter
    index = 0

    non_companion_bodies(star).each do |body|
      if body.is_a?(Star)
        child_letter = assign_star(body, '')
        orbiting += child_letter
      elsif !body.is_a?(Planetoid)
        index += 1
        prefix = star.companion_id.present? && orbiting.length == 1 ? orbiting + 'ab' : orbiting
        body.update_column(:orbit_sequence, "#{prefix} #{RomanNumeral.convert(index)}")
      end
    end

    letter
  end

  def assign_planetoid_objects(star)
    belt_counters = Hash.new(0)
    belt_cache    = {} # belt_id => PlanetoidBelt (or nil)

    # Recurse into child stars
    star.stars.find_each { |child_star| assign_planetoid_objects(child_star) }

    # Number planetoids per belt
    star.stellar_objects.find_each do |body|
      next unless body.is_a?(Planetoid)

      belt_id = body.data&.dig('planetoid_belt_id') || body.data&.dig(:planetoid_belt_id)
      next if belt_id.blank?

      belt_id = belt_id.to_i

      belt = belt_cache.fetch(belt_id) do
        belt_cache[belt_id] = StellarObject.find_by(id: belt_id, type: 'PlanetoidBelt')
      end
      next unless belt

      belt_counters[belt_id] += 1
      body.update_column(:orbit_sequence, "#{belt.orbit_sequence}.#{belt_counters[belt_id]}")
    end
  end

  def non_companion_bodies(star)
    bodies = star.stellar_objects.reload.to_a
    stars = star.stars.reload.to_a
    stars = stars.reject { |s| s.id == star.companion_id } if star.companion_id.present?
    (bodies + stars).sort_by { |b| b.orbit.to_f }
  end
end
