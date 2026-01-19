# frozen_string_literal: true


class StarSystemImporter
  def import!(parsec, data)
    @parsec = parsec

    ActiveRecord::Base.transaction do
      @star_system = StarSystem.new
      @star_system.parsec = parsec
      @star_system.name = data['name']
      allegiance = data.fetch('allegiance')
      unless allegiance.nil?
        @star_system.allegiance = Allegiance.where(code: allegiance).sole
      end
      @star_system.save!

      unless data['mainWorld'].nil?
        set_star_system_trade_codes(data['mainWorld']['tradeCodes'])
      end

      primary_data = data['primaryStar']
      primary = Star.new
      primary.star_system = @star_system
      import_star(primary, primary_data)
      @star_system.main_world = @star_system.stellar_objects.find_by(orbit_sequence: data['mainWorldOrbitSequence'])
      @star_system.save!
    end
    @star_system
  end

  private

  def set_star_system_trade_codes(codes)
    return if codes.nil?
    codes.each do |code|
      StarSystemTradeCode.create!(star_system: @star_system, trade_code: TradeCode.find_by(code: code))
    end
  end

  def set_stellar_object_trade_codes(so, codes)
    return if codes.nil?
    codes.each do |code|
      StellarObjectTradeCode.create!(stellar_object: so, trade_code: TradeCode.find_by(code: code))
    end
  end

  def import_star(star, data)
    star.assign_data_from_generator(data)
    star.save!
    if data['companion']
      companion = Star.new
      companion.star_system = @star_system
      companion.orbiting = star
      import_star(companion, data['companion'])
    end
    data['stellarObjects'].each do |so_data|
      orbit_type = so_data['orbitType']
      if orbit_type < 10
        so = Star.new
        so.orbiting = star
        so.star_system = @star_system
        import_star(so, so_data)
      else
        klass = OrbitType::STI_CLASS_FOR_ORBIT_TYPE.fetch(orbit_type) do
          raise ArgumentError, "Unknown orbitType: #{orbit_type.inspect}"
        end
        so = klass.new
        so.orbiting_star = star
        so.assign_data_from_generator(so_data)
        so.save!
        set_stellar_object_trade_codes(so, so_data['tradeCodes'])
      end
    end
  end
end
