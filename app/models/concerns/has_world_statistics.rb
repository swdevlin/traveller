module HasWorldStatistics
  extend ActiveSupport::Concern

  def number_of_systems
    systems_scope.count
  end

  def number_of_populated_worlds
    worlds_scope.count
  end

  def gwp
    worlds_scope
      .where("(data -> 'economics' ->> 'totalGWP') IS NOT NULL")
      .sum(Arel.sql("(data -> 'economics' ->> 'totalGWP')::float"))
  end

  def total_population
    worlds_scope
      .where("(data -> 'population' ->> 'censusPopulation') IS NOT NULL")
      .sum(Arel.sql("(data -> 'population' ->> 'censusPopulation')::bigint"))
  end

  def worlds_with_known_census_count
    worlds_scope.where("(data -> 'population' ->> 'censusPopulation') IS NOT NULL").count
  end

  def highest_population_world
    worlds_scope
      .order(Arel.sql("(data -> 'population' ->> 'code')::integer DESC"),
             Arel.sql("(data -> 'population' ->> 'censusPopulation')::bigint DESC NULLS LAST"))
      .first
  end

  def highest_tech_level_world
    worlds_scope
      .where("(data -> 'tech_level' ->> 'code') IS NOT NULL")
      .order(Arel.sql("(data -> 'tech_level' ->> 'code')::integer DESC"))
      .first
  end

  def tech_level_histogram
    worlds_scope
      .where("(data -> 'tech_level' ->> 'code') IS NOT NULL")
      .group(Arel.sql("(data -> 'tech_level' ->> 'code')::integer"))
      .count
      .sort.to_h
  end

  def government_histogram
    worlds_scope
      .where("(data -> 'government' ->> 'code') IS NOT NULL")
      .group(Arel.sql("(data -> 'government' ->> 'code')::integer"))
      .count
      .sort.to_h
  end

  def law_level_histogram
    worlds_scope
      .where("(data -> 'law_level' ->> 'code') IS NOT NULL")
      .group(Arel.sql("(data -> 'law_level' ->> 'code')::integer"))
      .count
      .sort.to_h
  end

  def starport_histogram
    worlds_scope
      .where("(data ->> 'starport_code') IS NOT NULL")
      .group(Arel.sql("data ->> 'starport_code'"))
      .count
  end

  def travel_zone_histogram
    systems_scope.where.not(travel_zone_id: nil).group(:travel_zone_id).count
  end

  def allegiance_histogram
    systems_scope.where.not(allegiance_id: nil).group(:allegiance_id).count
  end

  def facility_histogram
    StarSystemFacility.where(star_system_id: systems_scope.select(:id)).group(:facility_id).count
  end

  def trade_code_histogram
    StellarObjectTradeCode
      .where(stellar_object_id: systems_scope.select(:main_world_id))
      .group(:trade_code_id).count
  end
end
