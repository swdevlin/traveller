# frozen_string_literal: true

# Derives a YAML build configuration from an existing subsector's database contents.
# The resulting config fully specifies each system (star tree + bodies in orbit order)
# so that feeding it back through the generator recreates the same subsector.
class SubsectorBuildConfigExporter
  include StellarBuildExport

  def initialize(subsector)
    @subsector = subsector
    @ul, = subsector.universal_coordinates
  end

  def export
    config = base_config

    systems = build_systems
    config['systems'] = systems if systems.any?

    rogues = build_rogues
    config['rogues'] = rogues if rogues.any?

    config
  end

  def to_yaml
    YAML.dump(export)
  end

  private

  def base_config
    existing = @subsector.build.present? ? YAML.safe_load(@subsector.build) : {}
    existing = {} unless existing.is_a?(Hash)

    {
      'type'          => existing.fetch('type', 'STANDARD'),
      'language'      => existing['language'],
      'unusualChance' => existing['unusualChance'],
      'defaultSI'     => existing['defaultSI']
    }.compact
  end

  def build_systems
    @subsector.star_systems
              .includes(:parsec, :allegiance, :travel_zone, :facilities, :main_world,
                        stars: [:companion, { stars: :primary_stellar_objects }, :primary_stellar_objects])
              .map { |sys| export_system(sys) }
  end

  def build_rogues
    @subsector.rogues.includes(:parsec).filter_map { |rogue| export_rogue(rogue) }
  end

  def subsector_xy(parsec)
    x = parsec.x - @ul.x + 1
    y = @ul.y - parsec.y + 1
    [x, y]
  end

  def export_system(star_system)
    x, y = subsector_xy(star_system.parsec)
    entry = { 'x' => x, 'y' => y }

    entry['name']        = star_system.name                if star_system.name.present?
    entry['language']    = star_system.language            if star_system.language.present?
    entry['allegiance']  = star_system.allegiance.code     if star_system.allegiance
    entry['travelZone']  = star_system.travel_zone.code    if star_system.travel_zone
    entry['surveyIndex'] = star_system.survey_index        if star_system.survey_index.present?

    bases = star_system.facilities.map(&:code)
    entry['bases'] = bases if bases.any?

    primary = star_system.primary_star
    entry['primary'] = export_star(primary, star_system.main_world_id) if primary

    entry
  end

  def export_rogue(rogue)
    type = rogue_type_string(rogue)
    return nil if type.nil?

    x, y  = subsector_xy(rogue.parsec)
    entry = { 'x' => x, 'y' => y, 'type' => type }
    entry['name']  = rogue.name if rogue.name.present?
    entry['known'] = true       if rogue.known
    entry
  end
end
