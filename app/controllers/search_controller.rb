# frozen_string_literal: true

class SearchController < ApplicationController
  LIMIT = 12

  def query
    q = params[:q].to_s.strip
    return render json: [] if q.length < 3

    results = search(q)
    render json: results
  end

  private

  def search(q)
    sql = <<~SQL
      SELECT type, name, id, score, meta FROM (
        SELECT
          'Star System' AS type,
          star_systems.name,
          star_systems.id,
          word_similarity($1, star_systems.name) AS score,
          sec.name || ' · ' ||
            LPAD((parsecs.x - sec.x * 32 + 1)::text, 2, '0') ||
            LPAD((sec.y * 40 - parsecs.y + 1)::text, 2, '0') ||
            CASE WHEN so.uwp IS NOT NULL THEN ' · ' || so.uwp ELSE '' END AS meta
        FROM star_systems
        JOIN parsecs ON parsecs.id = star_systems.parsec_id
        JOIN sectors sec ON sec.id = parsecs.sector_id
        LEFT JOIN stellar_objects so ON so.id = star_systems.main_world_id
        WHERE star_systems.name IS NOT NULL AND $1 <% star_systems.name

        UNION ALL

        SELECT
          'Sector' AS type,
          name,
          id,
          word_similarity($1, name) AS score,
          '(' || x::text || ', ' || y::text || ')' AS meta
        FROM sectors
        WHERE name IS NOT NULL AND $1 <% name

        UNION ALL

        SELECT
          'Subsector' AS type,
          subsectors.name,
          subsectors.id,
          word_similarity($1, subsectors.name) AS score,
          sectors.name AS meta
        FROM subsectors
        JOIN sectors ON sectors.id = subsectors.sector_id
        WHERE subsectors.name IS NOT NULL AND $1 <% subsectors.name
      ) results
      ORDER BY score DESC, name ASC
      LIMIT $2
    SQL

    rows = ActiveRecord::Base.connection.exec_query(sql, 'Search', [q, LIMIT])

    rows.map do |row|
      {
        type: row['type'],
        name: row['name'],
        meta: row['meta'],
        url: url_for_result(row['type'], row['id'])
      }
    end
  end

  def url_for_result(type, id)
    case type
    when 'Star System' then star_system_path(id)
    when 'Sector'      then sector_path(id)
    when 'Subsector'   then subsector_path(id)
    end
  end
end
