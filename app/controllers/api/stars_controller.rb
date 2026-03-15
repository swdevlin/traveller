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

    # Columns: id(0) system_id(1) data(2) au(3) diameter(4) companion_id(5)
    all_stars = StellarObject
      .where(type: 'Star', star_system_id: ids)
      .order(:au)
      .pluck(:id, :star_system_id, :data, :au, :diameter, :companion_id)

    companion_ids = all_stars.filter_map { |row| row[5] }.to_set

    companion_by_id = all_stars
      .select { |row| companion_ids.include?(row[0]) }
      .to_h do |row|
        id, _, d, au, diameter, _ = row
        d = JSON.parse(d) if d.is_a?(String)
        [id, build_star_hash(d, au, diameter, nil)]
      end

    stars_by_system = all_stars
      .reject { |row| companion_ids.include?(row[0]) }
      .group_by { |row| row[1] }

    result = systems.map do |ss|
      parsec = ss.parsec
      sector = parsec.sector
      uwp    = main_world_uwps[ss.main_world_id]
      tech_level = uwp ? uwp.split('-').last&.to_i(16) : nil

      {
        id:                ss.id,
        name:              ss.name.presence || '',
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
        stars:             (stars_by_system[ss.id] || []).map do |row|
          _, _, d, au, diameter, companion_id = row
          d = JSON.parse(d) if d.is_a?(String)
          build_star_hash(d, au, diameter, companion_by_id[companion_id])
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

  private

  def build_star_hash(d, au, diameter, companion)
    {
      colour:          d['colour'],
      stellar_class:   d['stellar_class'],
      stellar_type:    d['stellar_type'],
      stellar_subtype: d['stellar_subtype'],
      luminosity:      d['luminosity'],
      diameter:        diameter,
      hzco:            d['hzco'],
      au:              au || 0,
      companion:       companion
    }
  end
end
