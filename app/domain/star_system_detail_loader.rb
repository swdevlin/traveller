# frozen_string_literal: true

# Loads a star system with everything the detail JSON (api/_star_system_detail)
# reads, in a fixed number of queries however many bodies it has.
#
# A busy system has hundreds of bodies, and the detail view asks each one for
# its moons, rings, planet map and tags. Left to load lazily that is hundreds of
# queries per request, so this loads each of them for the whole system at once.
#
#   StarSystemDetailLoader.new(parsec.star_systems, referee: true).load
#
# `referee` says whether tags will be shown, which only the referee sees; they
# are not loaded otherwise.
class StarSystemDetailLoader
  BODY = [{ moons: %i[allegiance orbiting] }, :allegiance, :orbiting, :rings].freeze
  STAR = [{ stellar_objects: BODY }, :companion].freeze
  INCLUDES = [{ parsec: { sector: :subsectors } }, :allegiance, :facilities,
              { stars: [*STAR, { stars: STAR }] }, { main_world: :trade_codes }].freeze

  def initialize(scope, referee:)
    @scope = scope
    @referee = referee
  end

  # The first matching star system, loaded, or nil.
  def load
    system = @scope.includes(*INCLUDES).first
    preload_planet_maps(system) if system
    preload_tags(system) if system && @referee
    system
  end

  private

  def preload_planet_maps(system)
    mapped = (bodies(system) + moons(system)).select { |body| body.class.reflect_on_association(:planet_map) }
    ActiveRecord::Associations::Preloader.new(records: mapped, associations: { planet_map: :webp_attachment }).call
  end

  def preload_tags(system)
    taggable = [system, system.main_world, *stars(system), *bodies(system), *moons(system), *rings(system)].compact.uniq
    ActiveRecord::Associations::Preloader.new(records: taggable, associations: :tags).call
  end

  # Every star in the system, including those orbiting another star and companions.
  def stars(system)
    system.stars.flat_map { |star| [star, *star.stars, star.companion] }.compact.uniq
  end

  def bodies(system) = stars(system).flat_map { |star| star.stellar_objects.to_a }.uniq

  def moons(system) = bodies(system).flat_map { |body| body.moons.to_a }

  def rings(system) = bodies(system).flat_map { |body| body.rings.to_a }
end
