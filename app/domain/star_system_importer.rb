# frozen_string_literal: true


class StarSystemImporter
  def import!(parsec, data)
    @parsec = parsec

    ActiveRecord::Base.transaction do
      @star_system = StarSystem.new
      @star_system.parsec = parsec
      @star_system.name = data['name']
      @star_system.save!

      primary_data = data['stars'][0]
      primary = Star.new
      primary.star_system = @star_system
      import_star(primary, primary_data)
    end
    @star_system
  end

  private

  def import_star(star, data)
    star.assign_data_from_generator(data)
    star.save!
    data['stellarObjects'].each do |so_data|
      orbit_type = so_data['orbitType']
      klass = OrbitType::STI_CLASS_FOR_ORBIT_TYPE.fetch(orbit_type) do
        raise ArgumentError, "Unknown orbitType: #{orbit_type.inspect}"
      end

      so = klass.new
      so.orbiting = star
      so.star_system = @star_system
      if klass == Star
        import_star(so, so_data)
      else
        so.assign_data_from_generator(so_data)
        so.save!
      end
    end
  end
end
