# frozen_string_literal: true

# A ring orbits its parent planet like a moon does. Both `orbit` (the distance of the ring's centre from
# the planet) and `span` (its radial width) are in planetary diameters.
class Ring < StellarObject
  store_accessor :data, :span

  before_validation :normalize_span

  validates :orbit, presence: true
  validates :span, numericality: { greater_than: 0 }

  def self.allowed_data_keys
    %i[span]
  end

  def self.permitted_params
    [:name, :player_notes, :referee_notes, :tag_list, :reference_url, :orbit, data: [:span]]
  end

  # The generator sends a ring as { orbit, span }.
  def self.from_generator(planet, payload)
    new(
      orbiting: planet,
      star_system_id: planet.star_system_id,
      orbit: payload['orbit'],
      data: { 'span' => payload['span'] }
    )
  end

  # A ring has no physical or social characteristics, only its orbit and span.
  def edit_sections
    %w[general]
  end

  def inner_edge
    orbit - (span / 2.0)
  end

  def outer_edge
    orbit + (span / 2.0)
  end

  def distance_km
    orbiting&.diameter && (orbit * orbiting.diameter)
  end

  def width_km
    orbiting&.diameter && (span * orbiting.diameter)
  end

  private

  def normalize_span
    self.span = span.to_f if span.present?
  end
end
