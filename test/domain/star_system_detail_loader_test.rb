# frozen_string_literal: true

require 'test_helper'

class StarSystemDetailLoaderTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @sector = Sector.create!(name: 'Loader Test Sector', x: 90, y: 90, abbreviation: 'Ldr')
    parsec = Parsec.create!(sector: @sector, x: 90 * 32, y: 90 * 40)
    @system = StarSystem.create!(name: 'Loader System', parsec: parsec, known: true)
    @star = Star.create!(star_system: @system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V',
                         diameter: 1_392_000, jump_shadow: 139_200_000)
    @url = "/c/#{@campaign.slug}/api/star_systems/#{@system.id}"
    @lookup_url = "/c/#{@campaign.slug}/api/parsecs/lookup?sx=90&sy=90&hx=1&hy=1"
  end

  # A planet with a moon, a ring and tags, so each association a body is asked for is exercised.
  def add_planet(orbit)
    planet = TerrestrialPlanet.create!(
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5, population_code: 6, government_code: 5,
      law_level_code: 5, tech_level_code: 8, starport_code: 'A', orbiting: @star, orbit: orbit,
      au: orbit, diameter: 12_742
    )
    Moon.create!(name: "Moon #{orbit}", orbiting: planet, orbit: 2, au: 0.01, size_code: 'S').update!(tag_names: ['moon-tag'])
    Ring.create!(name: "Ring #{orbit}", orbiting: planet, orbit: 0.9, data: { 'span' => 0.25 }).update!(tag_names: ['ring-tag'])
    planet.update!(tag_names: ['planet-tag'])
    planet
  end

  test 'loads the whole tree of a system' do
    planet = add_planet(1.0)

    system = StarSystemDetailLoader.new(StarSystem.where(id: @system.id), referee: true).load

    loaded_planet = system.stars.first.stellar_objects.detect { |body| body.id == planet.id }
    assert loaded_planet.association(:moons).loaded?
    assert loaded_planet.association(:rings).loaded?
    assert loaded_planet.association(:tags).loaded?
    assert loaded_planet.association(:planet_map).loaded?
  end

  test 'returns nil when nothing matches' do
    assert_nil StarSystemDetailLoader.new(StarSystem.where(id: 0), referee: false).load
  end

  test 'does not load tags for a request that cannot show them' do
    planet = add_planet(1.0)

    system = StarSystemDetailLoader.new(StarSystem.where(id: @system.id), referee: false).load

    loaded_planet = system.stars.first.stellar_objects.detect { |body| body.id == planet.id }
    assert_not loaded_planet.association(:tags).loaded?
  end

  # The number of queries the block runs. (assert_queries_count returns the block's
  # result, not a count, so it cannot be used to compare two requests.)
  def count_queries
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == 'SCHEMA' || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { yield }
    count
  end

  # Queries for the three ways the detail is served: to the referee by id, to the
  # referee by hex, and to a player (who is not shown tags).
  def detail_query_counts
    sign_in_as users(:one)
    counts = [@url, @lookup_url].map do |url|
      count_queries { get url, as: :json }.tap { assert_response :success }
    end
    sign_out
    counts << count_queries { get @url, as: :json }.tap { assert_response :success }
  end

  test 'serving a system does not issue queries per body' do
    add_planet(1.0)
    queries_for_one = detail_query_counts

    2.times { |i| add_planet(2.0 + i) }

    assert_equal queries_for_one, detail_query_counts
  end

  test 'tags are still shown to the referee only' do
    sign_in_as users(:one)
    planet = add_planet(1.0)

    get @url, as: :json
    body = response.parsed_body['primary_star']['stellar_objects'].detect { |object| object['id'] == planet.id }
    assert_equal ['planet-tag'], body['tags']

    sign_out
    get @url, as: :json
    body = response.parsed_body['primary_star']['stellar_objects'].detect { |object| object['id'] == planet.id }
    assert_equal [], body['tags']
  end
end
