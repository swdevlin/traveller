class Api::StarsController < Api::BaseController
  def index
    parsec_scope = parsecs_in_region
    if parsec_scope.nil?
      return render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
                   status: :bad_request
    end

    systems = StarSystem
      .where(parsec: parsec_scope)
      .includes({ parsec: :sector }, :allegiance)

    ids = systems.map(&:id)
    return render json: [] if ids.empty?

    main_world_uwps = StellarObject
      .where(id: systems.map(&:main_world_id).compact)
      .pluck(:id, :uwp).to_h

    native_ids = StellarObject
      .where(star_system_id: ids)
      .where("data->>'native_sophont' = 'true'")
      .pluck(:star_system_id).to_set

    extinct_ids = StellarObject
      .where(star_system_id: ids)
      .where("data->>'extinct_sophont' = 'true'")
      .pluck(:star_system_id).to_set

    stars_by_system = StellarObject
      .where(type: 'Star', star_system_id: ids)
      .pluck(:star_system_id, :data)
      .group_by(&:first)

    result = systems.map do |ss|
      parsec = ss.parsec
      sector = parsec.sector
      uwp    = main_world_uwps[ss.main_world_id]
      tech_level = uwp ? uwp.split('-').last&.to_i(16) : nil

      {
        id:                ss.id,
        name:              ss.name,
        survey_index:      ss.survey_index,
        gas_giant_count:   ss.gas_giant_count,
        terrestrial_count: ss.terrestrial_count,
        belt_count:        ss.belt_count,
        sector_x:          sector.x,
        sector_y:          sector.y,
        sector_name:       sector.name,
        x:                 parsec.x - sector.x * 32 + 1,
        y:                 sector.y * 40 - parsec.y + 1,
        origin_x:          parsec.x,
        origin_y:          parsec.y,
        scan_points:       0,
        allegiance:        ss.allegiance&.code,
        native_sophont:    native_ids.include?(ss.id),
        extinct_sophont:   extinct_ids.include?(ss.id),
        star_count:        (stars_by_system[ss.id] || []).size,
        tech_level:        tech_level,
        stars:             (stars_by_system[ss.id] || []).map do |_, d|
          d = JSON.parse(d) if d.is_a?(String)
          {
            colour:          d['colour'],
            stellar_class:   d['stellarClass'],
            stellar_type:    d['stellarType'],
            stellar_subtype: d['subtype'],
            luminosity:      d['luminosity']
          }
        end
      }
    end

    render json: result
  end

  def update
    star_system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'not found' }, status: :not_found unless star_system

    permitted = params.require(:star).permit(:survey_index, :name)
    if star_system.update(permitted)
      render json: star_system
    else
      render json: { errors: star_system.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
