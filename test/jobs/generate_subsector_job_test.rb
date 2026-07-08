require 'test_helper'

class GenerateSubsectorJobTest < ActiveJob::TestCase
  def setup
    @subsector = subsectors(:subsector_1_1)
    @ul, = @subsector.universal_coordinates
    @base = Rails.application.config.x.generator_service
    campaigns(:one).update_column(:schema_name, Apartment::Tenant.current)
  end

  # Mirrors CreateSubsectorJob's cube coordinate assignment.
  def create_parsec(hex_x, hex_y)
    x = @ul.x + hex_x - 1
    y = @ul.y - (hex_y - 1)
    q = x
    r = -y - ((x - (x & 1)) / 2)
    Parsec.create!(sector: sectors(:one), x: x, y: y, q: q, r: r, s: -q - r)
  end

  def stub_subsector_generator(systems, &request_capture)
    stub = stub_request(:post, "#{@base}/subsector")
    stub = stub.with(&request_capture) if request_capture
    stub.to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: systems.to_json)
  end

  test 'creates rogues at both levels and strips them from the generator payload' do
    rogue_parsec = create_parsec(3, 4)
    system_parsec = create_parsec(5, 2)

    system = JSON.parse(file_fixture('star_system_import_minimal.json').read).merge('x' => 5, 'y' => 2)
    posted = nil
    stub_subsector_generator([system]) { |req| posted = JSON.parse(req.body) }

    definition = <<~YAML
      type: STANDARD
      rogues:
        - x: 3
          y: 4
          type: relic
          name: The Monolith
      systems:
        - x: 5
          y: 2
          rogues:
            - type: gas cloud
              known: true
    YAML

    GenerateSubsectorJob.perform_now(@subsector.id, definition)

    relic = rogue_parsec.rogues.sole
    assert_instance_of Relic, relic
    assert_equal 'The Monolith', relic.name

    assert_equal 1, system_parsec.star_systems.count
    gas_cloud = system_parsec.rogues.sole
    assert_instance_of GasCloud, gas_cloud
    assert gas_cloud.known

    assert_not posted.key?('rogues')
    assert posted['systems'].none? { |s| s.key?('rogues') }
  end

  test 'config bases take precedence over generator response bases' do
    system_parsec = create_parsec(5, 2)
    system = JSON.parse(file_fixture('star_system_import_minimal.json').read)
      .merge('x' => 5, 'y' => 2, 'bases' => [facilities(:one).code])
    stub_subsector_generator([system])

    definition = <<~YAML
      type: STANDARD
      systems:
        - x: 5
          y: 2
          bases:
            - #{facilities(:two).code}
    YAML

    GenerateSubsectorJob.perform_now(@subsector.id, definition)

    star_system = system_parsec.star_systems.sole
    assert_equal [facilities(:two).code], star_system.facilities.pluck(:code)
  end

  test 'empty config bases overrides generator response bases with no facilities' do
    system_parsec = create_parsec(5, 2)
    system = JSON.parse(file_fixture('star_system_import_minimal.json').read)
      .merge('x' => 5, 'y' => 2, 'bases' => [facilities(:one).code])
    stub_subsector_generator([system])

    definition = <<~YAML
      type: STANDARD
      systems:
        - x: 5
          y: 2
          bases: []
    YAML

    GenerateSubsectorJob.perform_now(@subsector.id, definition)

    star_system = system_parsec.star_systems.sole
    assert_empty star_system.facilities
  end

  test 'falls back to generator response bases when config specifies none' do
    system_parsec = create_parsec(5, 2)
    system = JSON.parse(file_fixture('star_system_import_minimal.json').read)
      .merge('x' => 5, 'y' => 2, 'bases' => [facilities(:one).code])
    stub_subsector_generator([system])

    definition = <<~YAML
      type: STANDARD
      systems:
        - x: 5
          y: 2
    YAML

    GenerateSubsectorJob.perform_now(@subsector.id, definition)

    star_system = system_parsec.star_systems.sole
    assert_equal [facilities(:one).code], star_system.facilities.pluck(:code)
  end

  test 'skips rogues in hexes whose star system is locked' do
    star_systems(:in_one).update_column(:locked, true)

    stub_subsector_generator([])

    definition = <<~YAML
      type: STANDARD
      rogues:
        - x: 1
          y: 1
          type: relic
    YAML

    assert_no_difference -> { parsecs(:one).rogues.count } do
      GenerateSubsectorJob.perform_now(@subsector.id, definition)
    end

    assert_empty parsecs(:one).rogues.where(type: 'Relic')
  end

  test 'a failing rogue does not abort the remaining rogues' do
    rogue_parsec = create_parsec(3, 4)

    stub_subsector_generator([])
    stub_request(:get, "#{@base}/gas_giant").with(query: { 'size' => 'GL' }).to_return(status: 500, body: 'boom')

    definition = <<~YAML
      type: STANDARD
      rogues:
        - x: 3
          y: 4
          type: large gas giant
        - x: 3
          y: 4
          type: relic
    YAML

    GenerateSubsectorJob.perform_now(@subsector.id, definition)

    assert_instance_of Relic, rogue_parsec.rogues.sole
  end

  test 'imports jump routes for the sector after generating' do
    sectors(:one).update_column(:source, 'traveller_map')
    create_parsec(2, 2)
    system_a = JSON.parse(file_fixture('star_system_import_minimal.json').read).merge('x' => 1, 'y' => 1)
    system_b = JSON.parse(file_fixture('star_system_import_minimal.json').read).merge('x' => 2, 'y' => 2)
    stub_subsector_generator([system_a, system_b])
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=1&sy=-1')
      .to_return(status: 200, body: { 'Routes' => [{ 'Start' => '0101', 'End' => '0202' }] }.to_json)

    definition = <<~YAML
      type: STANDARD
    YAML

    # subsector.clear (run at the start of the job) destroys subsector 1,1's
    # existing star systems, which cascades and destroys the fixture jump_route_link
    # tying star_systems(:in_one) to star_systems(:in_two) - so overall JumpRouteLink
    # count is not a reliable delta here; assert on the specific new record instead.
    GenerateSubsectorJob.perform_now(@subsector.id, definition)

    jump_route = JumpRoute.find_by(travellermap_allegiance_code: 'Im')
    assert jump_route
    link = jump_route.jump_route_links.sole
    hex_a_system = Parsec.find_by(sector: sectors(:one), x: @ul.x, y: @ul.y).star_systems.sole
    hex_b_system = Parsec.find_by(sector: sectors(:one), x: @ul.x + 1, y: @ul.y - 1).star_systems.sole
    assert_equal [hex_a_system.id, hex_b_system.id].sort, [link.from_star_system_id, link.to_star_system_id]
  end

  test 'reimports jump routes for a neighbouring sector, catching routes that could not resolve earlier' do
    sectors(:one).update_column(:source, 'traveller_map')
    sectors(:two).update_column(:source, 'traveller_map')
    create_parsec(2, 2)
    system = JSON.parse(file_fixture('star_system_import_minimal.json').read).merge('x' => 2, 'y' => 2)
    stub_subsector_generator([system])

    # Simulate sector two (the northern neighbour, y: 2) having been populated earlier, with
    # a route into sector one that could not resolve at the time because sector one's system
    # did not exist yet.
    ul_two = sectors(:two).upper_left
    q = ul_two.x
    r = -ul_two.y - ((ul_two.x - (ul_two.x & 1)) / 2)
    other_parsec = Parsec.create!(sector: sectors(:two), x: ul_two.x, y: ul_two.y, q: q, r: r, s: -q - r)
    StarSystem.create!(parsec: other_parsec)

    stub_request(:get, 'https://travellermap.com/api/metadata?sx=1&sy=-1')
      .to_return(status: 200, body: { 'Routes' => [] }.to_json)
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=1&sy=-2')
      .to_return(status: 200, body: { 'Routes' => [{ 'Start' => '0101', 'End' => '0202', 'EndOffsetY' => 1 }] }.to_json)

    definition = <<~YAML
      type: STANDARD
    YAML

    GenerateSubsectorJob.perform_now(@subsector.id, definition)

    jump_route = JumpRoute.find_by(travellermap_allegiance_code: 'Im')
    assert jump_route
    link = jump_route.jump_route_links.sole
    hex_a_system = Parsec.find_by(sector: sectors(:one), x: @ul.x + 1, y: @ul.y - 1).star_systems.sole
    assert_includes [link.from_star_system_id, link.to_star_system_id], hex_a_system.id
    assert_includes [link.from_star_system_id, link.to_star_system_id], other_parsec.star_systems.sole.id
  end

  test 'a jump route metadata failure does not prevent the job from completing' do
    sectors(:one).update_column(:source, 'traveller_map')
    stub_subsector_generator([])
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=1&sy=-1').to_timeout

    definition = <<~YAML
      type: STANDARD
    YAML

    assert_nothing_raised do
      GenerateSubsectorJob.perform_now(@subsector.id, definition)
    end
  end
end
