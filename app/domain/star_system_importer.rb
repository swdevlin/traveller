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
  def import!(parsec, data)
    @parsec = parsec

    ActiveRecord::Base.transaction do
      @star_system = StarSystem.new
      @star_system.parsec = parsec
      @star_system.name = data['name']
      @star_system.build_log = data['buildLog']
      @star_system.survey_index = data['surveyIndex'] || 0
      allegiance = data.fetch('allegiance')
      unless allegiance.nil?
        @star_system.allegiance = Allegiance.where(code: allegiance).sole
      end
      @star_system.save!

      unless data['mainWorld'].nil?
        set_star_system_trade_codes(data['mainWorld']['tradeCodes'])
      end

      @deferred_belt_assignments = []

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
    end
    @star_system
  end

  private

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
        so.assign_moons(so_data['moons'])
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
