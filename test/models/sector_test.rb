require 'test_helper'

class SectorTest < ActiveSupport::TestCase
  test 'effective_language returns own language when set' do
    campaign = campaigns(:one)
    sector = Sector.new(x: 99, y: 99, language: 'aslan')
    assert_equal 'aslan', sector.effective_language(campaign)
  end

  test 'effective_language falls back to campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'nordic'
    sector = Sector.new(x: 99, y: 99)
    assert_equal 'nordic', sector.effective_language(campaign)
  end

  test 'effective_language own language overrides campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'nordic'
    sector = Sector.new(x: 99, y: 99, language: 'aslan')
    assert_equal 'aslan', sector.effective_language(campaign)
  end

  test 'effective_language returns nil when nothing set' do
    campaign = campaigns(:one)
    assert_nil Sector.new(x: 99, y: 99).effective_language(campaign)
  end

  test 'validates language must be a recognised language' do
    sector = sectors(:one)
    sector.language = 'klingon'
    assert_not sector.valid?
    assert sector.errors[:language].any?
  end

  test 'validates language allows blank' do
    sector = sectors(:one)
    sector.language = ''
    assert sector.valid?
  end

  def stub_metadata(x, y, status: 200, body: nil)
    stub_request(:get, "https://travellermap.com/api/metadata?sx=#{x}&sy=#{-y}")
      .to_return(status: status, body: body || { 'Subsectors' => [] }.to_json)
  end

  test 'traveller_map sector is valid and saves when metadata fetch succeeds' do
    stub_metadata(50, 50)
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert sector.save
  end

  test 'traveller_map sector is invalid when metadata fetch returns a non-2xx status' do
    stub_metadata(50, 50, status: 500, body: 'boom')
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert_not sector.save
    assert sector.errors[:base].any?
  end

  test 'traveller_map sector is invalid on a network timeout' do
    stub_request(:get, %r{travellermap\.com/api/metadata}).to_timeout
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert_not sector.save
    assert sector.errors[:base].any?
  end

  test 'traveller_map sector is invalid when the response body is not valid JSON' do
    stub_metadata(50, 50, body: 'not json')
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert_not sector.save
    assert sector.errors[:base].any?
  end

  test 'traveller_map sector is invalid when the response is an empty JSON object' do
    stub_metadata(50, 50, body: '{}')
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    assert_not sector.save
    assert sector.errors[:base].any?
  end

  test 'requests the correct query string sign for x and y' do
    stub = stub_metadata(50, 50)
    sector = Sector.new(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    sector.save!

    assert_requested stub
  end

  test 'creates jump routes from metadata at sector-creation time for already-existing neighbours' do
    neighbour = Sector.create!(name: 'Neighbour', x: 50, y: 51, abbreviation: 'NB', skip_subsector_creation: true)
    ul = neighbour.upper_left
    parsec_a = Parsec.create!(sector: neighbour, x: ul.x, y: ul.y, q: ul.x, r: -ul.y - ((ul.x - (ul.x & 1)) / 2), s: 0)
    parsec_a.update!(s: -parsec_a.q - parsec_a.r)
    parsec_b = Parsec.create!(sector: neighbour, x: ul.x + 1, y: ul.y - 1, q: ul.x + 1, r: -(ul.y - 1) - (((ul.x + 1) - ((ul.x + 1) & 1)) / 2), s: 0)
    parsec_b.update!(s: -parsec_b.q - parsec_b.r)
    system_a = StarSystem.create!(name: 'A', parsec: parsec_a)
    system_b = StarSystem.create!(name: 'B', parsec: parsec_b)

    stub_metadata(50, 50, body: {
      'Subsectors' => [],
      'Routes' => [{ 'Start' => '0101', 'End' => '0202', 'StartOffsetY' => -1, 'EndOffsetY' => -1 }]
    }.to_json)

    Sector.create!(name: 'New One', x: 50, y: 50, abbreviation: 'NO1', source: 'traveller_map')

    jump_route = JumpRoute.find_by(travellermap_allegiance_code: 'Im')
    assert jump_route
    low_id, high_id = [system_a.id, system_b.id].sort
    assert JumpRouteLink.exists?(from_star_system_id: low_id, to_star_system_id: high_id)
  end
end
