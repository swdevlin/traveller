# frozen_string_literal: true


IMPORT_ORBIT_TYPES = {
  primary: 0,
  close: 1,
  near: 2,
  far: 3,
  companion: 4,
  gas_giant: 10,
  terrestrial: 11,
  planetoid_belt: 12,
  planetoid: 13
}.freeze

IMPORT_STAR_ORBIT_TYPES = IMPORT_ORBIT_TYPES.select { |_name, value| value < 10 }.values.to_set.freeze

class StarSystemImporter
  def reimport!(star_system, data, config_bases: nil)
    @parsec      = star_system.parsec
    @star_system = star_system

    ActiveRecord::Base.transaction do
      StellarObjectTradeCode
        .where(stellar_object_id: StellarObject.where(star_system_id: @star_system.id).select(:id))
        .delete_all
      StellarObject.where(star_system_id: @star_system.id).delete_all
      StarSystemTradeCode.where(star_system_id: @star_system.id).delete_all
      StarSystemFacility.where(star_system_id: @star_system.id).delete_all
      @star_system.update_column(:main_world_id, nil)

      @star_system.name         = data['name']
      @star_system.build_log    = data['buildLog']
      @star_system.survey_index = data['surveyIndex'] || 0
      allegiance_code           = data.fetch('allegiance')
      @star_system.allegiance   = allegiance_code ? find_or_create_allegiance(allegiance_code) : nil
      @star_system.save!

      set_star_system_trade_codes(data['mainWorld']['tradeCodes']) unless data['mainWorld'].nil?
      set_star_system_facilities(data, config_bases)

      @deferred_belt_assignments = []
      @deferred_tidal_lock_assignments = []
      primary = Star.new
      primary.skip_import_callbacks = true
      primary.star_system = @star_system
      import_star(primary, data['primaryStar'])

      @deferred_belt_assignments.each do |entry|
        belt = entry[:star].stellar_objects
                           .find_by(type: 'PlanetoidBelt', orbit_sequence: entry[:belt_orbit_seq])
        entry[:planetoid].update!(planetoid_belt_id: belt.id) if belt
      end

      resolve_tidal_lock_targets

      main_world_orbit_sequence = data['mainWorldOrbitSequence']
      @star_system.main_world =
        @star_system.stellar_objects.find_by(orbit_sequence: main_world_orbit_sequence) ||
        Moon.find_by(star_system_id: @star_system.id, orbit_sequence: main_world_orbit_sequence)
      unless @star_system.main_world.nil?
        if @star_system.main_world.name.blank? && @star_system.name.present?
          @star_system.main_world.name = @star_system.name
          @star_system.main_world.save!
        end
      end
      @star_system.save!
      @star_system.recalculate_world_counts!
      @star_system.recalculate_sophont_flags!
    end
    @star_system
  end

  def import!(parsec, data, campaign: nil, subsector_language: nil,
              system_language: nil, main_world_language: nil, system_name: nil, config_bases: nil)
    @parsec = parsec
    @campaign = campaign
    @subsector_language = subsector_language
    @system_language = system_language
    @main_world_language = main_world_language

    ActiveRecord::Base.transaction do
      @star_system = StarSystem.new
      @star_system.parsec = parsec
      @star_system.name = resolve_system_name(system_name, data['name'])
      @star_system.language = system_language if system_language.present?
      @star_system.build_log = data['buildLog']
      @star_system.survey_index = data['surveyIndex'] || 0
      allegiance = data['allegiance']
      unless allegiance.nil?
        @star_system.allegiance = find_or_create_allegiance(allegiance)
      end
      @star_system.save!

      unless data['mainWorld'].nil?
        set_star_system_trade_codes(data['mainWorld']['tradeCodes'])
      end
      set_star_system_facilities(data, config_bases)

      @deferred_belt_assignments = []
      @deferred_tidal_lock_assignments = []

      primary_data = data['primaryStar']
      primary = Star.new
      primary.skip_import_callbacks = true
      primary.star_system = @star_system
      import_star(primary, primary_data)

      @deferred_belt_assignments.each do |entry|
        belt = entry[:star].stellar_objects
                           .find_by(type: 'PlanetoidBelt', orbit_sequence: entry[:belt_orbit_seq])
        entry[:planetoid].update!(planetoid_belt_id: belt.id) if belt
      end

      resolve_tidal_lock_targets

      main_world_orbit_sequence = data['mainWorldOrbitSequence']
      @star_system.main_world =
        @star_system.stellar_objects.find_by(orbit_sequence: main_world_orbit_sequence) ||
        Moon.find_by(star_system_id: @star_system.id, orbit_sequence: main_world_orbit_sequence)
      unless @star_system.main_world.nil?
        if @star_system.main_world.name.blank? || effective_system_language.present?
          @star_system.main_world.name = resolve_main_world_name
          @star_system.main_world.language = main_world_language if main_world_language.present?
          @star_system.main_world.save!
        end
      end
      @star_system.save!
      @star_system.recalculate_world_counts!
      @star_system.recalculate_sophont_flags!
    end
    @star_system
  end

  private

  def effective_system_language
    @system_language.presence || @subsector_language.presence || @campaign&.default_language.presence
  end

  def effective_main_world_language
    @main_world_language.presence || effective_system_language
  end

  def resolve_system_name(yaml_name, generator_name)
    return yaml_name if yaml_name.present?

    lang = effective_system_language
    return WordGenerator.new(language: lang.to_sym).generate if lang.present?

    generator_name
  end

  def resolve_main_world_name
    mw_lang = effective_main_world_language
    sys_lang = effective_system_language
    if mw_lang.present? && mw_lang != sys_lang
      WordGenerator.new(language: mw_lang.to_sym).generate
    else
      @star_system.name
    end
  end

  def resolve_tidal_lock_targets
    return if @deferred_tidal_lock_assignments.blank?

    objects_by_orbit_seq = StellarObject
      .where(star_system_id: @star_system.id)
      .index_by(&:orbit_sequence)

    @deferred_tidal_lock_assignments.each do |entry|
      target = objects_by_orbit_seq[entry[:orbit_sequence]]
      entry[:object].update_column(:tidal_lock_target_id, target.id) if target
    end
  end

  def find_or_create_allegiance(code)
    Allegiance.find_or_create_by!(code: code) do |a|
      a.name = code
    end
  end

  def set_star_system_trade_codes(codes)
    return if codes.nil?

    codes.uniq.each do |code|
      trade_code = TradeCode.find_by(code: code)
      next unless trade_code

      StarSystemTradeCode.find_or_create_by!(
        star_system: @star_system,
        trade_code: trade_code
      )
    end
  end

  def set_star_system_facilities(data, config_bases)
    codes = resolve_base_codes(data, config_bases)
    return if codes.blank?

    Facility.where(code: codes).find_each do |facility|
      StarSystemFacility.find_or_create_by!(star_system: @star_system, facility: facility)
    end
  end

  def resolve_base_codes(data, config_bases)
    return Array(config_bases).reject(&:blank?) unless config_bases.nil?

    Array(data['bases']).reject(&:blank?).presence
  end

  def set_stellar_object_trade_codes(stellar_object, codes)
    return if codes.nil?

    codes.uniq.each do |code|
      trade_code = TradeCode.find_by(code: code)
      next unless trade_code

      StellarObjectTradeCode.find_or_create_by!(
        stellar_object: stellar_object,
        trade_code: trade_code
      )
    end
  end

  def import_star(star, data)
    star.assign_data_from_generator(data)
    star.save!
    if data['companion']
      companion = Star.new
      companion.skip_import_callbacks = true
      companion.star_system = @star_system
      companion.orbiting = star
      import_star(companion, data['companion'])
      star.companion = companion
      star.save!
    end
    data['stellarObjects'].each do |so_data|
      orbit_type = so_data['orbitType']
      if IMPORT_STAR_ORBIT_TYPES.include?(orbit_type)
        unless orbit_type == IMPORT_ORBIT_TYPES[:companion]
          so = Star.new
          so.skip_import_callbacks = true
          so.orbiting = star
          so.star_system = @star_system
          import_star(so, so_data)
        end
      else
        klass = OrbitType::STI_CLASS_FOR_ORBIT_TYPE.fetch(orbit_type) do
          raise ArgumentError, "Unknown orbitType: #{orbit_type.inspect}"
        end
        so = klass.new
        so.skip_import_callbacks = true
        so.orbiting = star
        so.assign_data_from_generator(so_data)
        so.save!
        tidal_lock_orbit_seq = so_data['tidalLockTarget']
        if tidal_lock_orbit_seq.present?
          @deferred_tidal_lock_assignments << { object: so, orbit_sequence: tidal_lock_orbit_seq }
        elsif so_data['tidalLock'].present?
          so.update_column(:tidal_lock_target_id, star.id)
        end
        moon_tidal_locks = so.assign_moons(so_data['moons'])
        moon_tidal_locks.each do |entry|
          moon = Moon.find_by(star_system_id: @star_system.id, orbit_sequence: entry[:orbit_sequence])
          @deferred_tidal_lock_assignments << { object: moon, orbit_sequence: entry[:tidal_lock_orbit_seq] } if moon
        end
        set_stellar_object_trade_codes(so, so_data['tradeCodes'])
        if klass == Planetoid && so_data['belt'].present?
          @deferred_belt_assignments << {
            planetoid: so,
            star: star,
            belt_orbit_seq: so_data['belt']['orbitSequence']
          }
        end
      end
    rescue => e
      Rails.logger.error("import_star failed on stellarObject: #{e.message} | star=#{star.orbit_sequence.inspect} | so_data=#{so_data.inspect}")
      raise
    end
  end
end
