# frozen_string_literal: true

require 'test_helper'

# GET /star_systems?q= : finding systems from typed text, for every picker.
class Api::StarSystemsSearchTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @base = "/c/#{@campaign.slug}/api/star_systems"
    @sector = Sector.create!(name: 'Spinward Marches', x: 96, y: 96, abbreviation: 'Spi')
    @other_sector = Sector.create!(name: 'Deneb', x: 97, y: 96, abbreviation: 'Den')
  end

  # A system at hex (col, row) of `sector`, using the same maths as the hex code.
  def build_system(sector, col, row, **attrs)
    parsec = Parsec.create!(sector: sector, x: sector.x * 32 + col - 1, y: sector.y * 40 - row + 1)
    StarSystem.create!({ parsec: parsec, known: true }.merge(attrs))
  end

  def search_for(params = {}, headers = {})
    get @base, params: params, headers: headers
    assert_response :success
    response.parsed_body
  end

  test 'finds systems by name, best match first' do
    zeta = build_system(@sector, 19, 10, name: 'Zeta Prime')
    build_system(@sector, 5, 5, name: 'Unrelated')

    results = search_for(q: 'Zeta Prime')

    assert_equal [zeta.id], results.map { |r| r['id'] }
    assert_equal 'Zeta Prime', results.first['name']
    assert_equal 'Spinward Marches · 1910', results.first['meta']
  end

  test 'returns only id, name and meta' do
    build_system(@sector, 1, 1, name: 'Zeta Prime')

    assert_equal %w[id meta name], search_for(q: 'Zeta Prime').first.keys.sort
  end

  test 'returns an empty list for a short query' do
    build_system(@sector, 1, 1, name: 'Zeta Prime')

    assert_equal [], search_for(q: 'ze')
    assert_equal [], search_for({})
  end

  test 'finds systems by a full hex code' do
    system = build_system(@sector, 19, 10, name: 'Zeta Prime')
    build_system(@sector, 19, 11, name: 'Other')

    assert_equal [system.id], search_for(q: '1910').map { |r| r['id'] }
  end

  test 'a partial hex code matches the hexes that start with it' do
    a = build_system(@sector, 19, 10, name: 'Aaa One')
    b = build_system(@sector, 19, 11, name: 'Bbb Two')
    build_system(@sector, 20, 10, name: 'Ccc Three')

    assert_equal [a.id, b.id].sort, search_for(q: '191').map { |r| r['id'] }.sort
  end

  test 'a name and a hex find the system at that hex in the sector with that name' do
    spinward = build_system(@sector, 19, 10, name: 'Zeta Prime')
    build_system(@other_sector, 19, 10, name: 'Deneb Gate')

    assert_equal [spinward.id], search_for(q: 'Spinward 1910').map { |r| r['id'] }
  end

  test 'an unnamed system found by hex is named after its sector and hex' do
    system = build_system(@sector, 19, 10, name: nil)

    result = search_for(q: '1910').find { |r| r['id'] == system.id }

    assert_equal 'Spinward Marches 1910', result['name']
  end

  test 'a sector name with no matching system lists that sector\'s systems' do
    a = build_system(@sector, 1, 1, name: 'Aaa One')
    build_system(@other_sector, 1, 1, name: 'Bbb Two')

    assert_equal [a.id], search_for(q: 'Spinward').map { |r| r['id'] }
  end

  test 'a system name is preferred over the sector fallback' do
    named = build_system(@other_sector, 1, 1, name: 'Spinward Gate')
    build_system(@sector, 2, 2, name: 'Aaa One')

    assert_equal [named.id], search_for(q: 'Spinward Gate').map { |r| r['id'] }
  end

  test 'sector_id limits the results to that sector' do
    mine = build_system(@sector, 1, 1, name: 'Zeta Prime')
    build_system(@other_sector, 1, 1, name: 'Zeta Major')

    assert_equal [mine.id], search_for(q: 'Zeta', sector_id: @sector.id).map { |r| r['id'] }
    assert_equal 2, search_for(q: 'Zeta').size
  end

  test 'sector_id also limits hex results' do
    mine = build_system(@sector, 19, 10, name: 'Zeta Prime')
    build_system(@other_sector, 19, 10, name: 'Deneb Gate')

    assert_equal [mine.id], search_for(q: '1910', sector_id: @sector.id).map { |r| r['id'] }
  end

  test 'a sector_id that is not a whole number is a bad request' do
    get @base, params: { q: 'Zeta', sector_id: 'abc' }

    assert_response :bad_request
    assert_equal 'sector_id must be a whole number', response.parsed_body['error']
  end

  test 'players see only known or surveyed systems, however they are found' do
    build_system(@sector, 19, 10, name: 'Zeta Prime', known: false, survey_index: 0)
    surveyed = build_system(@sector, 19, 11, name: 'Zeta Major', known: false, survey_index: 10)
    known = build_system(@sector, 19, 12, name: 'Zeta Minor', known: true)

    assert_equal [known.id, surveyed.id].sort, search_for(q: 'Zeta').map { |r| r['id'] }.sort
    assert_equal [], search_for(q: '1910')
    assert_equal [], search_for(q: 'Spinward 1910')
  end

  test 'a referee session sees every system' do
    hidden = build_system(@sector, 19, 10, name: 'Zeta Prime', known: false, survey_index: 0)
    sign_in_as users(:one)

    assert_equal [hidden.id], search_for(q: 'Zeta Prime').map { |r| r['id'] }
    assert_equal [hidden.id], search_for(q: '1910').map { |r| r['id'] }
  end

  test 'the API token sees every system' do
    hidden = build_system(@sector, 19, 10, name: 'Zeta Prime', known: false, survey_index: 0)

    results = search_for({ q: 'Zeta Prime' }, { 'Authorization' => "Bearer #{@campaign.api_token}" })

    assert_equal [hidden.id], results.map { |r| r['id'] }
  end

  test 'a signed-in user who is not the referee sees only what players see' do
    build_system(@sector, 19, 10, name: 'Zeta Prime', known: false, survey_index: 0)
    sign_in_as users(:two)

    assert_equal [], search_for(q: 'Zeta Prime')
  end

  test 'returns at most 12 results' do
    14.times { |i| build_system(@sector, 1, i + 1, name: "Zeta #{i}") }

    assert_equal 12, search_for(q: 'Zeta').size
  end
end
