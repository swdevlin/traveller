# frozen_string_literal: true

# World statistics for a sector and each of its subsectors, from two queries.
#
# The sector page used to ask every subsector (and the sector itself) for each
# figure separately, which re-derived the same star system / stellar object
# join about a hundred times. Here the sector's systems and populated bodies
# are loaded once and bucketed into subsectors by parsec coordinates in Ruby.
#
# The totals only change when something inside the sector does, which touches
# Sector#updated_at (see SectorMapVersion), so they are cached against it.
# Allegiances and the highest population world are looked up fresh by id.
#
# Responds to the same statistics methods as HasWorldStatistics, so it can be
# handed to the helpers that format them.
class SectorStatistics
  POPULATION_CODE = "(data -> 'population' ->> 'code')::integer"
  CENSUS_POPULATION = "(data -> 'population' ->> 'censusPopulation')::bigint"
  TECH_LEVEL_CODE = "(data -> 'tech_level' ->> 'code')::integer"

  CACHE_VERSION = 1

  SUBSECTOR_COLUMNS = 8
  SUBSECTOR_ROWS = 10

  Totals = Struct.new(:systems, :populated_systems, :worlds, :census_worlds, :population, :highest_tech_level_code, :allegiance_ids) do
    def initialize
      super(0, 0, 0, 0, 0, nil, Set.new)
    end
  end

  # The figures for one subsector, named as on Subsector.
  class Summary
    def initialize(totals, allegiances_by_id)
      @totals = totals
      @allegiances_by_id = allegiances_by_id
    end

    def number_of_star_systems = @totals.systems
    def number_of_populated_star_systems = @totals.populated_systems
    def worlds_with_known_census_count = @totals.census_worlds
    def total_population = @totals.population
    def highest_tech_level_code = @totals.highest_tech_level_code

    def allegiances
      @allegiances_by_id.values_at(*@totals.allegiance_ids).compact.sort_by(&:code)
    end
  end

  def initialize(sector)
    @sector = sector
    @sector_totals, totals_by_key, @highest_population_world_id =
      Rails.cache.fetch(cache_key) { compute }
    @allegiances_by_id = Allegiance.where(id: @sector_totals.allegiance_ids.to_a).index_by(&:id)
    @summaries = totals_by_key.transform_values { |totals| Summary.new(totals, @allegiances_by_id) }
  end

  def summary_for(subsector)
    @summaries[[subsector.x, subsector.y]] || Summary.new(Totals.new, @allegiances_by_id)
  end

  def number_of_star_systems = @sector_totals.systems
  def number_of_populated_worlds = @sector_totals.worlds
  def worlds_with_known_census_count = @sector_totals.census_worlds
  def total_population = @sector_totals.population
  def highest_tech_level_code = @sector_totals.highest_tech_level_code
  def allegiance_count = @sector_totals.allegiance_ids.size

  def highest_population_world
    return if @highest_population_world_id.nil?

    @highest_population_world ||= StellarObject.find_by(id: @highest_population_world_id)
  end

  private

  def cache_key
    ['sector_statistics', CACHE_VERSION, Apartment::Tenant.current, @sector.cache_key_with_version]
  end

  def compute
    system_rows = StarSystem.joins(:parsec)
                            .where(parsecs: { sector_id: @sector.id })
                            .pluck('star_systems.id', 'parsecs.x', 'parsecs.y', 'star_systems.allegiance_id')

    sector_totals = Totals.new
    totals_by_key = Hash.new { |h, k| h[k] = Totals.new }
    key_by_system_id = {}
    origin = @sector.universal_coordinates.first

    system_rows.each do |id, x, y, allegiance_id|
      key = [(x - origin.x) / SUBSECTOR_COLUMNS + 1, (origin.y - y) / SUBSECTOR_ROWS + 1]
      key_by_system_id[id] = key
      [sector_totals, totals_by_key[key]].each do |totals|
        totals.systems += 1
        totals.allegiance_ids << allegiance_id if allegiance_id
      end
    end

    system_ids = StarSystem.where(parsec_id: @sector.parsecs.select(:id)).select(:id)
    bodies = StellarObject
             .where(star_system_id: system_ids)
             .populated
             .pluck(:id, :type, :star_system_id, Arel.sql(POPULATION_CODE), Arel.sql(CENSUS_POPULATION), Arel.sql(TECH_LEVEL_CODE))

    populated_system_ids = Set.new
    highest = nil

    bodies.each do |id, type, system_id, population_code, census, tech_level|
      populated_system_ids << system_id
      next unless StellarObject::POPULATED_WORLD_TYPES.include?(type)

      key = key_by_system_id[system_id]
      next unless key

      [sector_totals, totals_by_key[key]].each do |totals|
        totals.worlds += 1
        if census
          totals.census_worlds += 1
          totals.population += census
        end
        if tech_level && (totals.highest_tech_level_code.nil? || tech_level > totals.highest_tech_level_code)
          totals.highest_tech_level_code = tech_level
        end
      end

      rank = [population_code, census || -1]
      highest = [rank, id] if highest.nil? || (rank <=> highest.first) == 1
    end

    populated_system_ids.each do |system_id|
      key = key_by_system_id[system_id]
      next unless key

      sector_totals.populated_systems += 1
      totals_by_key[key].populated_systems += 1
    end

    [sector_totals, totals_by_key.to_a.to_h, highest&.last]
  end
end
