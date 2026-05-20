# frozen_string_literal: true

class SearchController < ApplicationController
  LIMIT = 12

  def query
    q = params[:q].to_s.strip
    return render json: [] if q.length < 3

    results = search(q)
    render json: results
  end

  def star_systems
    q = params[:q].to_s.strip
    return render json: [] if q.length < 3

    name_part, hex_part = split_query(q)

    name_rows   = name_part.present? ? star_system_name_results(name_part).to_a : []
    hex_rows    = hex_part ? star_system_hex_results(hex_part, name_part).to_a : []
    sector_rows = (hex_part.nil? && name_rows.empty? && name_part.present?) ?
                    sector_name_system_results(name_part).to_a : []

    render json: deduplicated(name_rows + hex_rows + sector_rows)
                   .map { |r| { id: r['id'], name: r['name'], meta: r['meta'] } }
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

  HEX_CODE_SQL = <<~SQL.squish.freeze
    LPAD((parsecs.x - sec.x * 32 + 1)::text, 2, '0') ||
    LPAD((sec.y * 40 - parsecs.y + 1)::text, 2, '0')
  SQL

  # Returns [name_part, hex_part].
  # hex_part is 1–4 digits; fewer than 4 means a prefix (LIKE) match.
  def split_query(q)
    if q.match?(/\A\d{1,4}\z/)
      [nil, q]
    elsif (m = q.match(/\A(.+?)\s+(\d{1,4})\z/))
      [m[1].strip, m[2]]
    else
      [q, nil]
    end
  end

  def deduplicated(rows)
    seen = Set.new
    rows.each_with_object([]) do |r, acc|
      next if seen.include?(r['id'])
      seen << r['id']
      acc << r
      break if acc.length >= LIMIT
    end
  end

  def star_system_name_results(q)
    sql = <<~SQL
      SELECT ss.id, ss.name,
             word_similarity($1, ss.name) AS score,
             sec.name || ' · ' || #{HEX_CODE_SQL} AS meta
      FROM star_systems ss
      JOIN parsecs ON parsecs.id = ss.parsec_id
      JOIN sectors sec ON sec.id = parsecs.sector_id
      WHERE ss.name IS NOT NULL AND $1 <% ss.name
      ORDER BY score DESC, ss.name ASC
      LIMIT #{LIMIT}
    SQL
    ActiveRecord::Base.connection.exec_query(sql, 'StarSystemNameSearch', [q])
  end

  def star_system_hex_results(hex_code, sector_q = nil)
    hex_match_sql = hex_code.length == 4 ? "(#{HEX_CODE_SQL}) = $1" : "(#{HEX_CODE_SQL}) LIKE ($1 || '%')"

    if sector_q.present?
      sql = <<~SQL
        SELECT ss.id,
               COALESCE(ss.name, sec.name || ' ' || (#{HEX_CODE_SQL})) AS name,
               word_similarity($2, sec.name) AS score,
               sec.name || ' · ' || (#{HEX_CODE_SQL}) AS meta
        FROM star_systems ss
        JOIN parsecs ON parsecs.id = ss.parsec_id
        JOIN sectors sec ON sec.id = parsecs.sector_id
        WHERE #{hex_match_sql} AND $2 <% sec.name
        ORDER BY score DESC, (#{HEX_CODE_SQL}) ASC
        LIMIT #{LIMIT}
      SQL
      ActiveRecord::Base.connection.exec_query(sql, 'StarSystemHexSearch', [hex_code, sector_q])
    else
      sql = <<~SQL
        SELECT ss.id,
               COALESCE(ss.name, sec.name || ' ' || (#{HEX_CODE_SQL})) AS name,
               1.0 AS score,
               sec.name || ' · ' || (#{HEX_CODE_SQL}) AS meta
        FROM star_systems ss
        JOIN parsecs ON parsecs.id = ss.parsec_id
        JOIN sectors sec ON sec.id = parsecs.sector_id
        WHERE #{hex_match_sql}
        ORDER BY (#{HEX_CODE_SQL}) ASC
        LIMIT #{LIMIT}
      SQL
      ActiveRecord::Base.connection.exec_query(sql, 'StarSystemHexSearch', [hex_code])
    end
  end

  def sector_name_system_results(sector_q)
    sql = <<~SQL
      SELECT ss.id,
             COALESCE(ss.name, sec.name || ' ' || (#{HEX_CODE_SQL})) AS name,
             word_similarity($1, sec.name) AS score,
             sec.name || ' · ' || (#{HEX_CODE_SQL}) AS meta
      FROM star_systems ss
      JOIN parsecs ON parsecs.id = ss.parsec_id
      JOIN sectors sec ON sec.id = parsecs.sector_id
      WHERE $1 <% sec.name
      ORDER BY score DESC, (#{HEX_CODE_SQL}) ASC
      LIMIT #{LIMIT}
    SQL
    ActiveRecord::Base.connection.exec_query(sql, 'StarSystemSectorSearch', [sector_q])
  end

  def url_for_result(type, id)
    case type
    when 'Star System' then star_system_path(id)
    when 'Sector'      then sector_path(id)
    when 'Subsector'   then subsector_path(id)
    end
  end
end
