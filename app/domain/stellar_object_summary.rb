# frozen_string_literal: true

# What the starmap needs of a planet, belt or gas giant before the viewer opens it: the side panel
# rows, the system map and the orbit map. Built straight from the record, so none of the
# descriptions, government, law level, tech level or population the full API object carries are
# worked out. The full object is fetched when it is opened (StarmapData::ObjectsController).
#
# Every key the Elm decoders in frontend/starmap/src/Traveller/StellarObject.elm treat as
# required must be here, or the whole system fails to decode. Elm ignores unknown keys.
class StellarObjectSummary
  COLUMNS = %w[id type name uwp size_code orbit au mass diameter inclination eccentricity effective_hzco_deviation].freeze

  # Generator data (the data JSONB) the starmap reads, under their snake_case keys.
  DATA_KEYS = %w[
    code orbit period axial_tilt retrograde albedo has_ring trojan_offset
    biomass_rating biocomplexity_rating biodiversity_rating compatibility_rating resource_rating
    native_sophont extinct_sophont m_type s_type c_type o_type span bulk
    planetoid_belt_id temperature
  ].freeze

  ATMOSPHERE_KEYS = %w[code taint bar density].freeze
  HYDROGRAPHICS_KEYS = %w[code distribution liquid percentage].freeze

  # `render_context` carries the system's city and planetoid counts, worked out once for all bodies.
  def self.from_record(body, campaign:, render_context:)
    data = snake(body.data || {})
    summary = COLUMNS.to_h { |column| [column, body.public_send(column)] } # accessors: a belt's diameter is 0, not a column
    summary['orbit_sequence'] = body.orbit_sequence || ''
    # the generator's data overrides the columns of the same name, as in the full object
    summary.merge!(data.slice(*DATA_KEYS, *(COLUMNS - %w[id type])))
    summary['orbit_position'] = { 'x' => body.orbit_x || 0.0, 'y' => body.orbit_y || 0.0 }
    summary['periapsis'] = body.periapsis
    summary['apoapsis'] = body.apoapsis
    summary['orbit_type'] = body.orbit_type if body.respond_to?(:orbit_type)
    summary['is_moon'] = false
    summary['reference_url'] = body.effective_reference_url(campaign)
    summary['jump_shadow'] = jump_shadow(body)
    add_uwp_details(summary, body, data) if body.is_a?(HasUwp)
    add_counts(summary, body, render_context)
    summary
  end

  def self.add_uwp_details(summary, body, data)
    atmosphere = data['atmosphere'].is_a?(Hash) ? data['atmosphere'] : {}
    summary['atmosphere'] = atmosphere.merge(body.atmosphere&.to_h || {}).slice(*ATMOSPHERE_KEYS)

    hydrographics = data['hydrographics'].is_a?(Hash) ? data['hydrographics'] : {}
    hydrographics = hydrographics.merge('code' => body.hydrographics_code, 'percentage' => body.hydrographics_percentage)
    liquid = body.hydrographics_liquid
    hydrographics['liquid'] = { 'label' => 'Liquid', 'value' => liquid } if liquid.present?
    distribution = body.hydrographics_distribution
    if distribution.present?
      hydrographics['distribution'] = { 'label' => 'Distribution', 'code' => distribution,
                                        'description' => StellarObjectsHelper::HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS[distribution] }
    end
    summary['hydrographics'] = hydrographics.slice(*HYDROGRAPHICS_KEYS)
  end

  def self.add_counts(summary, body, render_context)
    summary['city_count'] = render_context[:city_counts_by_stellar_object_id].fetch(body.id, 0) if body.respond_to?(:cities)
    return unless body.is_a?(PlanetoidBelt)

    summary['planetoid_count'] = render_context[:planetoid_counts_by_belt_id].fetch(body.id, 0)
  end

  def self.jump_shadow(body)
    km = body.effective_jump_shadow_km
    km&.positive? ? { 'distance_km' => km.round } : nil
  end

  def self.snake(value)
    case value
    when Hash then value.to_h { |key, val| [StellarObjectsHelper.snake_key(key), snake(val)] }
    when Array then value.map { |val| snake(val) }
    else value
    end
  end
end
