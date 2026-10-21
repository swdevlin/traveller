# frozen_string_literal: true

# Shared star/body/rogue export logic included by SubsectorBuildConfigExporter
# and StarSystemBuildConfigExporter.
module StellarBuildExport
  GAS_GIANT_SIZE_MAP = {
    'GS' => 'small gas giant',
    'GM' => 'medium gas giant',
    'GL' => 'large gas giant'
  }.freeze

  def export_star(star, main_world_id)
    hash = { 'type' => star_type_string(star) }
    hash['class'] = star.stellar_class if star.stellar_class.present? && !special_type?(star)
    hash['name']  = star.name         if star.name.present?

    bodies = star.primary_stellar_objects.order(:orbit).filter_map { |obj| export_body(obj, main_world_id) }
    hash['bodies'] = bodies if bodies.any?

    hash['companion'] = export_star(star.companion, main_world_id) if star.companion

    star.secondary_stars.each do |secondary|
      role = OrbitType.role_for_orbit(secondary.orbit)
      hash[role.to_s] = export_star(secondary, main_world_id) if role
    end

    hash
  end

  def star_type_string(star)
    return star.stellar_type if special_type?(star)

    "#{star.stellar_type}#{star.stellar_subtype.to_i}"
  end

  def special_type?(star)
    Star::SPECIAL_SPECTRAL_TYPES.key?(star.stellar_type)
  end

  def export_body(obj, main_world_id)
    uwp = body_uwp(obj)
    return nil if uwp.nil?

    entry = { 'uwp' => uwp }
    entry['name']      = obj.name     if obj.name.present?
    entry['language']  = obj.language if obj.language.present?
    entry['mainWorld'] = true         if obj.id == main_world_id
    export_satellites(obj, entry)
    entry
  end

  def export_satellites(obj, entry)
    return if obj.is_a?(PlanetoidBelt)

    moons = obj.moons.order(:orbit, :id).map { |moon| { 'uwp' => moon_uwp(moon) } }
    entry['moons'] = moons if moons.any?

    ring_count = obj.rings.count
    entry['ringCount'] = ring_count if ring_count.positive?
  end

  # The schema only accepts a full UWP, so size S (which UWP_CODE cannot express) is exported as a small
  # moon and anything malformed is left for the generator to choose.
  def moon_uwp(moon)
    return 'small moon' if moon.size_code == 'S'

    uwp = moon.uwp.to_s
    uwp = "X#{uwp}" if uwp.length == 8 && !uwp.match?(UWP_CODE)
    uwp.match?(UWP_CODE) ? uwp : 'random'
  end

  def body_uwp(obj)
    case obj
    when TerrestrialPlanet, Moon then obj.uwp
    when GasGiant                then GAS_GIANT_SIZE_MAP.fetch(obj.code, 'gas giant')
    when PlanetoidBelt           then 'planetoid belt'
    end
  end

  def rogue_type_string(rogue)
    case rogue
    when GasCloud          then 'gas cloud'
    when GravityAnomaly    then 'gravity anomaly'
    when InterstellarWreck then 'interstellar wreck'
    when PhantomObject     then 'phantom object'
    when RadiationCloud    then 'radiation cloud'
    when Relic             then 'relic'
    when SpaceStation      then 'space station'
    when UnusualObject     then 'unusual object'
    when Planetoid         then 'planetoid'
    when PlanetoidBelt     then 'planetoid belt'
    when TerrestrialPlanet then 'terrestrial planet'
    when Comet             then rogue.comet_type.present? ? "#{rogue.comet_type} comet" : 'comet'
    when GasGiant          then GAS_GIANT_SIZE_MAP.fetch(rogue.code, 'gas giant')
    end
  end
end
