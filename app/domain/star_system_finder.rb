# frozen_string_literal: true

# Finds star systems from text a person typed, for the pickers and search boxes
# that need to turn "Zeta Prime", "1910" or "Spinward 1910" into a system.
#
# The query is read as one of:
#   a name           fuzzy match on system names; if no system matches, on
#                    sector names, giving that sector's systems
#   a hex code       1-4 digits; fewer than 4 matches the hexes that start so
#   a name and hex   the system at that hex in a sector with that name (as
#                    well as systems with that name)
#
# Unless `referee` is true, only systems the players know of are returned: those
# marked known or with a survey index of at least 10.
#
# Returns up to LIMIT hashes of { id:, name:, meta: }. A system with no name is
# given "<sector> <hex>" as its name when found by hex or sector.
class StarSystemFinder
  LIMIT = 12
  MIN_QUERY_LENGTH = 3

  HEX_CODE_SQL = <<~SQL.squish.freeze
    LPAD((parsecs.x - sec.x * 32 + 1)::text, 2, '0') ||
    LPAD((sec.y * 40 - parsecs.y + 1)::text, 2, '0')
  SQL

  VISIBLE_SQL = '(ss.known = true OR ss.survey_index >= 10)'

  def initialize(query:, referee:, sector_id: nil)
    @query = query.to_s.strip
    @referee = referee
    @sector_id = sector_id
  end

  def call
    return [] if @query.length < MIN_QUERY_LENGTH

    name_part, hex_part = split_query

    name_rows = name_part.present? ? name_results(name_part) : []
    hex_rows = hex_part ? hex_results(hex_part, name_part) : []
    sector_rows = hex_part.nil? && name_rows.empty? && name_part.present? ? sector_name_results(name_part) : []

    (name_rows + hex_rows + sector_rows).uniq { |row| row['id'] }.first(LIMIT)
                                         .map { |row| { id: row['id'], name: row['name'], meta: row['meta'] } }
  end

  private

  # Returns [name_part, hex_part]; either may be nil.
  def split_query
    if @query.match?(/\A\d{1,4}\z/)
      [nil, @query]
    elsif (match = @query.match(/\A(.+?)\s+(\d{1,4})\z/))
      [match[1].strip, match[2]]
    else
      [@query, nil]
    end
  end

  def name_results(name)
    rows('StarSystemNameSearch') do |bind|
      term = bind.call(name)
      <<~SQL
        SELECT ss.id, ss.name,
               word_similarity(#{term}, ss.name) AS score,
               sec.name || ' · ' || #{HEX_CODE_SQL} AS meta
        FROM star_systems ss
        JOIN parsecs ON parsecs.id = ss.parsec_id
        JOIN sectors sec ON sec.id = parsecs.sector_id
        WHERE ss.name IS NOT NULL AND #{term} <% ss.name
          #{filters(bind)}
        ORDER BY score DESC, ss.name ASC
        LIMIT #{LIMIT}
      SQL
    end
  end

  def hex_results(hex_code, sector_name)
    rows('StarSystemHexSearch') do |bind|
      hex = bind.call(hex_code)
      hex_match = hex_code.length == 4 ? "(#{HEX_CODE_SQL}) = #{hex}" : "(#{HEX_CODE_SQL}) LIKE (#{hex} || '%')"
      sector = sector_name.present? ? bind.call(sector_name) : nil
      <<~SQL
        SELECT ss.id,
               COALESCE(ss.name, sec.name || ' ' || (#{HEX_CODE_SQL})) AS name,
               #{sector ? "word_similarity(#{sector}, sec.name)" : '1.0'} AS score,
               sec.name || ' · ' || (#{HEX_CODE_SQL}) AS meta
        FROM star_systems ss
        JOIN parsecs ON parsecs.id = ss.parsec_id
        JOIN sectors sec ON sec.id = parsecs.sector_id
        WHERE #{hex_match}
          #{"AND #{sector} <% sec.name" if sector}
          #{filters(bind)}
        ORDER BY #{sector ? 'score DESC, ' : ''}(#{HEX_CODE_SQL}) ASC
        LIMIT #{LIMIT}
      SQL
    end
  end

  def sector_name_results(sector_name)
    rows('StarSystemSectorSearch') do |bind|
      term = bind.call(sector_name)
      <<~SQL
        SELECT ss.id,
               COALESCE(ss.name, sec.name || ' ' || (#{HEX_CODE_SQL})) AS name,
               word_similarity(#{term}, sec.name) AS score,
               sec.name || ' · ' || (#{HEX_CODE_SQL}) AS meta
        FROM star_systems ss
        JOIN parsecs ON parsecs.id = ss.parsec_id
        JOIN sectors sec ON sec.id = parsecs.sector_id
        WHERE #{term} <% sec.name
          #{filters(bind)}
        ORDER BY score DESC, (#{HEX_CODE_SQL}) ASC
        LIMIT #{LIMIT}
      SQL
    end
  end

  # The conditions every query shares: what the players may see, and any filter.
  def filters(bind)
    clauses = []
    clauses << "AND #{VISIBLE_SQL}" unless @referee
    clauses << "AND parsecs.sector_id = #{bind.call(@sector_id)}" if @sector_id
    clauses.join(' ')
  end

  # Yields a bind callable that records a value and returns its $n placeholder,
  # and runs the SQL the block returns with those values.
  def rows(label)
    binds = []
    bind = lambda do |value|
      binds << value
      "$#{binds.size}"
    end
    sql = yield(bind)
    ActiveRecord::Base.connection.exec_query(sql, label, binds).to_a
  end
end
