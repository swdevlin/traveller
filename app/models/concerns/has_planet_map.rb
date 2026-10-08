module HasPlanetMap
  extend ActiveSupport::Concern

  UNMAPPABLE_SIZE_CODES = %w[0 S].freeze

  included do
    has_one :planet_map, foreign_key: :stellar_object_id, inverse_of: :stellar_object, dependent: :destroy
  end

  # Size 0 (ring/belt) and S (600 km) bodies are too small to map
  def map_supported? = UNMAPPABLE_SIZE_CODES.exclude?(size_code)

  # Fingerprint of everything the map is generated from. Cities are records rather than
  # part of `data`, so they are folded in explicitly.
  def map_inputs_digest
    inputs = as_json.merge('cities' => cities.order(:id).as_json(only: %i[id name city_type capital_designation population]))
    Digest::SHA256.hexdigest(inputs.to_json)
  end

  def map_stale?
    planet_map.present? && planet_map.inputs_digest != map_inputs_digest
  end

  # Rasterises first so a failure leaves any existing map untouched. Only the WebP is kept.
  def store_map(svg)
    data = SvgRasteriser.webp(svg)
    map = planet_map || build_planet_map
    map.webp.attach(io: StringIO.new(data), filename: 'map.webp', content_type: 'image/webp')
    map.inputs_digest = map_inputs_digest
    map.save!
  end
end
