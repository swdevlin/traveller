# frozen_string_literal: true

# Derives a YAML build configuration from an existing star system's database
# contents. The resulting config fully specifies the star tree and bodies so
# that feeding it back through the generator via the replace view recreates
# the same system.
class StarSystemBuildConfigExporter
  include StellarBuildExport

  def initialize(star_system)
    @star_system = star_system
  end

  def export
    config = {}

    config['name']        = @star_system.name            if @star_system.name.present?
    config['allegiance']  = @star_system.allegiance.code if @star_system.allegiance
    config['surveyIndex'] = @star_system.survey_index    if @star_system.survey_index.present?

    bases = @star_system.facilities.map(&:code)
    config['bases'] = bases if bases.any?

    primary = @star_system.primary_star
    config['primary'] = export_star(primary, @star_system.main_world_id) if primary

    rogues = build_rogues
    config['rogues'] = rogues if rogues.any?

    config
  end

  def to_yaml
    YAML.dump(export)
  end

  private

  def build_rogues
    @star_system.parsec.rogues.filter_map { |rogue| export_rogue(rogue) }
  end

  def export_rogue(rogue)
    type = rogue_type_string(rogue)
    return nil if type.nil?

    entry = { 'type' => type }
    entry['name']  = rogue.name if rogue.name.present?
    entry['known'] = true       if rogue.known
    entry
  end
end
