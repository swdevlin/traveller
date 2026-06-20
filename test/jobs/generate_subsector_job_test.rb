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
end
