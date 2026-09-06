class Api::StarMapController < Api::BaseController
  def index
    parsec_scope = parsecs_in_region
    if parsec_scope.nil?
      return render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
                   status: :bad_request
    end

    # `main_world: :trade_codes` fully instantiates a StellarObject (large jsonb
    # `data` column) per main world — only worth paying for when StrategicAnalysis
    # needs the rest of that object's attributes (imports/resource units/law
    # level/population stats aren't in the lean world_rows pluck below).
    # trade_codes itself never needs it — see main_world_trade_codes.
    needs_strategic = %w[Strategic Resource].include?(params[:display_mode])
    associations = [{ parsec: { sector: :subsectors } }, :allegiance, :travel_zone, :facilities]
    associations << { main_world: :trade_codes } if needs_strategic

    systems = StarSystem
      .where(parsec: parsec_scope)
      .includes(*associations)

    ids = systems.map(&:id)
    return render json: [] if ids.empty?

    authenticated_by_session?
    is_referee = Current.owns_campaign?

    main_world_ids = systems.filter_map(&:main_world_id)

    main_world_uwps = StellarObject
      .where(id: systems.map(&:main_world_id).compact)
      .pluck(:id, :uwp).to_h

    main_world_trade_codes = StellarObjectTradeCode
      .joins(:trade_code)
      .where(stellar_object_id: main_world_ids)
      .order('trade_codes.code')
      .pluck(:stellar_object_id, 'trade_codes.code')
      .group_by(&:first)
      .transform_values { |rows| rows.map(&:last) }

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

    # Main world data via JSONB extraction — avoids loading full data column
    world_rows = StellarObject
      .where(id: main_world_ids)
      .pluck(
        :id,
        :name,
        Arel.sql("(data -> 'economics' ->> 'worldTradeNumber')::float"),
        Arel.sql("(data -> 'economics' ->> 'totalGWP')::float"),
        Arel.sql("(data -> 'economics' ->> 'importance')::int"),
        Arel.sql("(data -> 'atmosphere' ->> 'code')::int"),
        Arel.sql("(data -> 'hydrographics' ->> 'code')::int"),
        Arel.sql("data ->> 'temperature'"),
        Arel.sql("data -> 'atmosphere' ->> 'density'"),
        Arel.sql("data -> 'atmosphere' -> 'taint' ->> 'code'"),
        Arel.sql("(data ->> 'habitability_rating')::int"),
        Arel.sql("(data -> 'government' ->> 'code')::int")
      )

    world_data = world_rows.index_by(&:first)
    governments_by_code = Government.all.pluck(:code, :government_type).to_h

    result = systems.map do |ss|
      parsec = ss.parsec
      sector = parsec.sector
      uwp    = main_world_uwps[ss.main_world_id]
      tech_level = uwp ? uwp.split('-').last&.to_i(16) : nil

      wd = world_data[ss.main_world_id]
      player_visible = is_referee || ss.known? || ss.survey_index >= 10
      allegiance_visible = is_referee || ss.allegiance&.known?

      world_name  = wd&.at(1)
      wtn         = player_visible ? wd&.at(2) : nil
      gwp         = player_visible ? wd&.at(3)&.round : nil
      importance  = player_visible ? wd&.at(4) : nil
      trade_codes = player_visible ? (main_world_trade_codes[ss.main_world_id] || []) : []
      image       = player_visible ? compute_image_name(wd&.at(5), wd&.at(6), wd&.at(7), wd&.at(8), wd&.at(9)) : nil
      main_world_name = player_visible ? world_name : nil
      # Referee-only: unlike wtn/gwp/importance, habitability stays hidden even once known?/surveyed.
      habitability_rating = is_referee ? wd&.at(10) : nil
      government_code = player_visible ? wd&.at(11) : nil
      government_name = government_code ? governments_by_code[government_code] : nil

      {
        id:                ss.id,
        name:              ss.name.presence || '',
        known:             ss.known?,
        survey_index:      ss.survey_index,
        gas_giant_count:   ss.gas_giant_count,
        terrestrial_count: ss.terrestrial_count,
        belt_count:        ss.belt_count,
        sector_x:          sector.x,
        sector_y:          sector.y,
        sector_name:       sector.name,
        sector_id:         sector.id,
        subsector_id:      parsec.subsector&.id,
        x:                 parsec.x - sector.x * 32 + 1,
        y:                 sector.y * 40 - parsec.y + 1,
        origin_x:          parsec.x,
        origin_y:          parsec.y,
        scan_points:       0,
        allegiance:        allegiance_visible ? ss.allegiance&.code : nil,
        allegiance_name:   allegiance_visible ? ss.allegiance&.name : nil,
        native_sophont:    native_ids.include?(ss.id),
        extinct_sophont:   extinct_ids.include?(ss.id),
        star_count:        (stars_by_system[ss.id] || []).size,
        tech_level:        tech_level,
        habitability_rating: habitability_rating,
        government_code:   government_code,
        government_name:   government_name,
        main_world_uwp:    uwp,
        main_world_name:   main_world_name,
        main_world_image:  image,
        wtn:               wtn,
        gwp:               gwp,
        importance:        importance,
        trade_codes:       trade_codes,
        bases:             player_visible ? ss.facilities.to_a.sort_by(&:code).map(&:code) : [],
        strategic:         (player_visible && needs_strategic) ? build_strategic_hash(ss) : nil,
        travel_zone:       ss.travel_zone ? { code: ss.travel_zone.code, colour: ss.travel_zone.colour } : nil,
        stars:             (stars_by_system[ss.id] || []).map do |row|
          _, _, d, au, diameter, companion_id = row
          d = JSON.parse(d) if d.is_a?(String)
          build_star_hash(d, au, diameter, companion_by_id[companion_id])
        end
      }
    end

    render json: result
  end

  private

  def compute_image_name(atmo, hydro, temp_str, density, taint_code)
    atmo       = atmo.to_i
    hydro      = hydro.to_i
    temp       = temp_str&.to_f
    density    = density.to_s
    taint_code = taint_code.to_s.upcase

    is_sparse = density.start_with?('Trace', 'Thin', 'Very Thin')

    return 'unusual'    if atmo == 10
    return 'corrosive'  if atmo == 11
    return 'insidious'  if atmo == 12
    return 'dense'      if atmo == 13
    return 'low'        if atmo == 14
    return 'unusual'    if atmo == 15
    return 'helium'     if atmo == 16
    return 'hydrogen'   if atmo == 17
    return 'biological' if taint_code == 'B'

    if hydro == 0
      return 'hot_rockball' if temp && temp > 473.15
      return 'trace'        if is_sparse
      return 'desert'
    end

    return 'molten' if temp && temp >= 673.15
    return 'ice'    if temp && temp < 263.15

    if atmo <= 9
      return 'waterworld'       if hydro == 10
      return "tp_#{hydro * 10}" if hydro >= 1 && hydro <= 9
    end

    nil
  end

  def build_strategic_hash(star_system)
    a = StrategicAnalysis.new(star_system)
    {
      importance_tier:     a.importance_tier,
      resource_units_tier: a.resource_units_tier,
      resource_tier:       a.resource_tier,
      trade_ease_tier:     a.trade_ease_tier,
      route_role:          a.route_role&.to_s
    }
  end

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
