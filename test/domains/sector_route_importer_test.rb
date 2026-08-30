require 'test_helper'

class SectorRouteImporterTest < ActiveSupport::TestCase
  def setup
    @sector = Sector.create!(name: 'Alpha', x: 10, y: 10, abbreviation: 'Alp')
    @neighbour = Sector.create!(name: 'Beta', x: 10, y: 11, abbreviation: 'Bet')
  end

  def build_star_system(sector, hex)
    ul = sector.upper_left
    x = ul.x + (hex[0, 2].to_i - 1)
    y = ul.y - (hex[2, 2].to_i - 1)
    q = x
    r = -y - ((x - (x & 1)) / 2)
    parsec = Parsec.create!(sector: sector, x: x, y: y, q: q, r: r, s: -q - r)
    StarSystem.create!(name: "System #{hex}", parsec: parsec)
  end

  test 'creates a link between two systems in the same sector, tagged with the given allegiance' do
    from = build_star_system(@sector, '0101')
    to = build_star_system(@sector, '0202')
    metadata = { 'Routes' => [{ 'Start' => '0101', 'End' => '0202', 'Allegiance' => 'FlLe' }] }

    stats = SectorRouteImporter.new(@sector, metadata).call

    assert_equal({ entries_total: 1, links_created: 1, links_skipped_existing: 0, entries_skipped_unresolved: 0 }, stats)

    jump_route = JumpRoute.find_by(travellermap_allegiance_code: 'FlLe')
    assert jump_route
    assert_equal 'network', jump_route.route_type
    assert jump_route.known?
    link = jump_route.jump_route_links.sole
    assert_equal [from.id, to.id].sort, [link.from_star_system_id, link.to_star_system_id]
  end

  test 'defaults to Im when Allegiance is absent or blank' do
    build_star_system(@sector, '0101')
    build_star_system(@sector, '0202')
    metadata = {
      'Routes' => [
        { 'Start' => '0101', 'End' => '0202' },
        { 'Start' => '0101', 'End' => '0202', 'Allegiance' => '' }
      ]
    }

    SectorRouteImporter.new(@sector, metadata).call

    assert_equal 1, JumpRoute.where(travellermap_allegiance_code: 'Im').count
    assert_nil JumpRoute.find_by(travellermap_allegiance_code: '')
  end

  test 'reuses an existing JumpRoute found by code even after the user renamed it' do
    build_star_system(@sector, '0101')
    build_star_system(@sector, '0202')
    existing = JumpRoute.create!(name: 'My Renamed Route', route_type: 'network',
                                  travellermap_allegiance_code: 'As', known: false)
    metadata = { 'Routes' => [{ 'Start' => '0101', 'End' => '0202', 'Allegiance' => 'As' }] }

    assert_no_difference -> { JumpRoute.count } do
      SectorRouteImporter.new(@sector, metadata).call
    end

    existing.reload
    assert_equal existing, existing.jump_route_links.sole.jump_route
    assert_not existing.known?
  end

  test 'skips a link that already exists, even under a different JumpRoute' do
    from = build_star_system(@sector, '0101')
    to = build_star_system(@sector, '0202')
    other_route = JumpRoute.create!(name: 'Other', route_type: 'network')
    JumpRouteLink.create!(jump_route: other_route, from_star_system_id: from.id, to_star_system_id: to.id)
    metadata = { 'Routes' => [{ 'Start' => '0101', 'End' => '0202', 'Allegiance' => 'Im' }] }

    stats = nil
    assert_no_difference -> { JumpRouteLink.count } do
      stats = SectorRouteImporter.new(@sector, metadata).call
    end

    assert_equal 0, stats[:links_created]
    assert_equal 1, stats[:links_skipped_existing]
  end

  test 'skips entries whose hex has no parsec yet' do
    build_star_system(@sector, '0101')
    metadata = { 'Routes' => [{ 'Start' => '0101', 'End' => '3140' }] }

    stats = SectorRouteImporter.new(@sector, metadata).call

    assert_equal 1, stats[:entries_skipped_unresolved]
    assert_equal 0, stats[:links_created]
  end

  test 'skips entries pointing at a neighbouring sector that does not exist yet' do
    build_star_system(@sector, '0101')
    metadata = { 'Routes' => [{ 'Start' => '0101', 'End' => '0101', 'EndOffsetX' => 5, 'EndOffsetY' => 5 }] }

    stats = SectorRouteImporter.new(@sector, metadata).call

    assert_equal 1, stats[:entries_skipped_unresolved]
  end

  test 'skips degenerate entries where Start and End resolve to the same system' do
    build_star_system(@sector, '0101')
    metadata = { 'Routes' => [{ 'Start' => '0101', 'End' => '0101' }] }

    stats = SectorRouteImporter.new(@sector, metadata).call

    assert_equal 1, stats[:entries_skipped_unresolved]
    assert_equal 0, stats[:links_created]
  end

  test 'resolves a cross-sector route via offset to the correct neighbouring sector' do
    from = build_star_system(@sector, '0140')
    to = build_star_system(@neighbour, '0101')

    # @sector is (10,10), @neighbour is (10,11): resolve_sector uses
    # x: sector.x + offset_x, y: sector.y - offset_y, so reaching y=11 from
    # y=10 requires offset_y: -1.
    metadata = { 'Routes' => [{ 'Start' => '0140', 'End' => '0101', 'EndOffsetY' => -1 }] }

    stats = SectorRouteImporter.new(@sector, metadata).call

    assert_equal 1, stats[:links_created]
    low_id, high_id = [from.id, to.id].sort
    link = JumpRouteLink.find_by(from_star_system_id: low_id, to_star_system_id: high_id)
    assert link
  end
end
