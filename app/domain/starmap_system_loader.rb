# frozen_string_literal: true

# Loads a star system for the starmap's click (StarmapData::HexesController): what
# StarSystemDetailLoader loads, less what only the full API object needs. The starmap's lean
# bodies (StellarObjectSummary) carry no moons, allegiance, planet map or tags, so none of
# those are loaded.
#
#   StarmapSystemLoader.new(parsec.star_systems, referee: true).load
class StarmapSystemLoader
  STAR = [{ stellar_objects: %i[rings orbiting] }, :companion].freeze
  INCLUDES = [{ parsec: { sector: :subsectors } }, :allegiance, :facilities,
              { stars: [*STAR, { stars: STAR }] }, { main_world: :trade_codes }].freeze

  def initialize(scope, referee:)
    @scope = scope
    @referee = referee
  end

  # The first matching star system, loaded, or nil.
  def load
    system = @scope.includes(*INCLUDES).first
    preload_tags(system) if system && @referee
    system
  end

  private

  # The system, its main world and its stars are the only records with tags in the lean tree.
  def preload_tags(system)
    stars = system.stars.flat_map { |star| [star, *star.stars, star.companion] }.compact.uniq
    ActiveRecord::Associations::Preloader.new(records: [system, system.main_world, *stars].compact.uniq, associations: :tags).call
  end
end
