# frozen_string_literal: true

class Api::SearchController < Api::BaseController
  LIMIT = 12

  def query
    q = params[:q].to_s.strip
    return render json: [] if q.length < 3

    authenticated_by_session?
    is_referee = Current.user.present?

    render json: search(q, is_referee)
  end

  private

  STELLAR_OBJECT_TYPES = %w[
    Comet GasCloud GasGiant GravityAnomaly InterstellarWreck
    PhantomObject PlanetoidBelt Planetoid RadiationCloud
    Relic SpaceStation TerrestrialPlanet UnusualObject
  ].freeze

  def search(q, is_referee)
    visibility_star_system = is_referee ? '' : 'AND (star_systems.known = true OR star_systems.survey_index >= 10)'
    visibility_stellar_obj = is_referee ? '' : 'AND (ss.known = true OR ss.survey_index >= 10)'

    sql = <<~SQL
      SELECT type, name, display_type, meta, x, y, sector_x, sector_y, subsector_x, subsector_y FROM (
        SELECT
          'StarSystem'  AS type,
          star_systems.name,
          'Star System' AS display_type,
          word_similarity($1, star_systems.name) AS score,
          sec.name || ' · ' ||
            LPAD((parsecs.x - sec.x * 32 + 1)::text, 2, '0') ||
            LPAD((sec.y * 40 - parsecs.y + 1)::text, 2, '0') ||
            CASE WHEN so.uwp IS NOT NULL THEN ' · ' || so.uwp ELSE '' END AS meta,
          parsecs.x     AS x,
          parsecs.y     AS y,
          NULL::integer AS sector_x,
          NULL::integer AS sector_y,
          NULL::integer AS subsector_x,
          NULL::integer AS subsector_y,
          1 AS sort_order
        FROM star_systems
        JOIN parsecs ON parsecs.id = star_systems.parsec_id
        JOIN sectors sec ON sec.id = parsecs.sector_id
        LEFT JOIN stellar_objects so ON so.id = star_systems.main_world_id
        WHERE star_systems.name IS NOT NULL
          AND $1 <% star_systems.name
          #{visibility_star_system}

        UNION ALL

        SELECT
          stellar_objects.type AS type,
          stellar_objects.name,
          stellar_objects.type AS display_type,
          word_similarity($1, stellar_objects.name) AS score,
          ss.name || ' · ' || sec.name AS meta,
          parsecs.x     AS x,
          parsecs.y     AS y,
          NULL::integer AS sector_x,
          NULL::integer AS sector_y,
          NULL::integer AS subsector_x,
          NULL::integer AS subsector_y,
          2 AS sort_order
        FROM stellar_objects
        JOIN star_systems ss ON ss.id = stellar_objects.star_system_id
        JOIN parsecs ON parsecs.id = ss.parsec_id
        JOIN sectors sec ON sec.id = parsecs.sector_id
        WHERE stellar_objects.name IS NOT NULL
          AND stellar_objects.type != 'Star'
          AND $1 <% stellar_objects.name
          #{visibility_stellar_obj}

        UNION ALL

        SELECT
          'Sector'      AS type,
          name,
          'Sector'      AS display_type,
          word_similarity($1, name) AS score,
          '(' || x::text || ', ' || y::text || ')' AS meta,
          NULL::integer AS x,
          NULL::integer AS y,
          x             AS sector_x,
          y             AS sector_y,
          NULL::integer AS subsector_x,
          NULL::integer AS subsector_y,
          3 AS sort_order
        FROM sectors
        WHERE name IS NOT NULL AND $1 <% name

        UNION ALL

        SELECT
          'Subsector'   AS type,
          subsectors.name,
          'Subsector'   AS display_type,
          word_similarity($1, subsectors.name) AS score,
          sectors.name  AS meta,
          NULL::integer AS x,
          NULL::integer AS y,
          sectors.x     AS sector_x,
          sectors.y     AS sector_y,
          subsectors.x  AS subsector_x,
          subsectors.y  AS subsector_y,
          4 AS sort_order
        FROM subsectors
        JOIN sectors ON sectors.id = subsectors.sector_id
        WHERE subsectors.name IS NOT NULL AND $1 <% subsectors.name
      ) results
      ORDER BY score DESC, sort_order ASC, name ASC
      LIMIT $2
    SQL

    rows = ActiveRecord::Base.connection.exec_query(sql, 'ApiSearch', [q, LIMIT])

    rows.map do |row|
      {
        type:         row['type'],
        display_type: humanize_type(row['display_type']),
        name:         row['name'],
        meta:         row['meta'],
        x:            row['x'],
        y:            row['y'],
        sector_x:     row['sector_x'],
        sector_y:     row['sector_y'],
        subsector_x:  row['subsector_x'],
        subsector_y:  row['subsector_y']
      }
    end
  end

  def humanize_type(type)
    return type unless STELLAR_OBJECT_TYPES.include?(type)

    type.scan(/[A-Z][a-z]*/).join(' ')
  end
end
