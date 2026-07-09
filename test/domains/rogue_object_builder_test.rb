# frozen_string_literal: true

require 'test_helper'

class RogueObjectBuilderTest < ActiveSupport::TestCase
  class StubTable
    def initialize(result)
      @result = result
    end

    def roll(**)
      @result
    end
  end

  class StubRoller
    def initialize(*results)
      @results = results
    end

    def roll(**)
      @results.shift
    end
  end

  GAS_GIANT_PAYLOAD = { 'code' => 'GM', 'diameter' => 120_000 }.freeze
  PLANETOID_BELT_PAYLOAD = { 'orbit' => 3.0, 'mType' => 50, 'sType' => 25, 'cType' => 25, 'oType' => 0 }.freeze
  PLANETOID_PAYLOAD = { 'size' => 3 }.freeze
  TERRESTRIAL_PAYLOAD = {
    'size' => 5,
    'atmosphere' => { 'code' => 4 },
    'hydrographics' => { 'code' => 1 }
  }.freeze

  def setup
    @parsec = parsecs(:one)
    @base = Rails.application.config.x.generator_service
  end

  def builder(roller: DiceRoller.new(seed: 42), rogue_table: RogueObjectsTable.new, size_table: GasGiantSizeTable.new)
    RogueObjectBuilder.new(
      generator_service: GeneratorService.new,
      roller: roller,
      rogue_table: rogue_table,
      size_table: size_table
    )
  end

  def stub_generator(endpoint, payload, query: nil)
    stub = stub_request(:get, "#{@base}/#{endpoint}")
    stub = stub.with(query: query) if query
    stub.to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: payload.to_json)
  end

  test 'simple type creates the STI class as a rogue' do
    rogue = builder.build!(@parsec, { 'type' => 'relic', 'name' => 'The Monolith', 'known' => true })

    assert_instance_of Relic, rogue
    assert_predicate rogue, :persisted?
    assert_equal @parsec.id, rogue.parsec_id
    assert_nil rogue.orbiting_id
    assert_equal 'The Monolith', rogue.name
    assert rogue.known
  end

  test 'every simple type maps to its class' do
    RogueObjectBuilder::SIMPLE_TYPES.each do |type, klass|
      rogue = builder.build!(@parsec, { 'type' => type })
      assert_instance_of klass, rogue
    end
  end

  test 'type is case-insensitive and whitespace-tolerant' do
    rogue = builder.build!(@parsec, { 'type' => '  Unusual   Object ' })

    assert_instance_of UnusualObject, rogue
  end

  test 'typed comet sets the comet type' do
    rogue = builder.build!(@parsec, { 'type' => 'inhabited comet' })

    assert_instance_of Comet, rogue
    assert_equal 'inhabited', rogue.comet_type
  end

  test 'bare comet picks a type with the roller' do
    rogue = builder(roller: StubRoller.new(4)).build!(@parsec, { 'type' => 'comet' })

    assert_equal 'inhabited', rogue.comet_type
  end

  test 'sized gas giant calls the generator with the size code' do
    stub = stub_generator('gas_giant', GAS_GIANT_PAYLOAD.merge('code' => 'GS'), query: { 'size' => 'GS' })

    rogue = builder.build!(@parsec, { 'type' => 'small gas giant' })

    assert_requested stub
    assert_instance_of GasGiant, rogue
    assert_equal 'GS', rogue.code
  end

  test 'bare gas giant rolls the size first' do
    stub = stub_generator('gas_giant', GAS_GIANT_PAYLOAD.merge('code' => 'GL'), query: { 'size' => 'GL' })

    rogue = builder(size_table: StubTable.new('GL')).build!(@parsec, { 'type' => 'gas giant' })

    assert_requested stub
    assert_instance_of GasGiant, rogue
  end

  test 'planetoid belt is generated' do
    stub = stub_generator('planetoid_belt', PLANETOID_BELT_PAYLOAD)

    rogue = builder.build!(@parsec, { 'type' => 'planetoid belt' })

    assert_requested stub
    assert_instance_of PlanetoidBelt, rogue
    assert_equal 3.0, rogue.orbit
  end

  test 'planetoid is generated' do
    stub = stub_generator('planetoid', PLANETOID_PAYLOAD)

    rogue = builder.build!(@parsec, { 'type' => 'planetoid' })

    assert_requested stub
    assert_instance_of Planetoid, rogue
    assert_equal '3', rogue.size_code
  end

  test 'terrestrial planet is generated' do
    stub = stub_generator('terrestrial_planet', TERRESTRIAL_PAYLOAD)

    rogue = builder.build!(@parsec, { 'type' => 'terrestrial planet' })

    assert_requested stub
    assert_instance_of TerrestrialPlanet, rogue
    assert_equal '5', rogue.size_code
  end

  test 'generator name does not override the configured name' do
    stub_generator('gas_giant', GAS_GIANT_PAYLOAD.merge('name' => 'Generated'), query: { 'size' => 'GS' })

    rogue = builder.build!(@parsec, { 'type' => 'small gas giant', 'name' => 'Behemoth' })

    assert_equal 'Behemoth', rogue.name
  end

  test 'random sensor glitch creates a phantom object with the description as notes' do
    table = StubTable.new({ id: :sensor_glitch, description: 'Sensor glitch; nothing present' })

    rogue = builder(rogue_table: table).build!(@parsec, { 'type' => 'random' })

    assert_instance_of PhantomObject, rogue
    assert_equal 'Sensor glitch; nothing present', rogue.notes
  end

  test 'random comet carries the comet type from the table' do
    table = StubTable.new({ id: :comet, comet_type: 'medium', description: 'Ice-bearing comet suitable for multiple refuelings' })

    rogue = builder(rogue_table: table).build!(@parsec, { 'type' => 'random' })

    assert_instance_of Comet, rogue
    assert_equal 'medium', rogue.comet_type
    assert_equal 'Ice-bearing comet suitable for multiple refuelings', rogue.notes
  end

  test 'random simple results map to their classes' do
    {
      unusual_object: UnusualObject,
      interstellar_wreck: InterstellarWreck,
      gas_cloud: GasCloud
    }.each do |id, klass|
      table = StubTable.new({ id: id, description: 'flavour' })

      rogue = builder(rogue_table: table).build!(@parsec, { 'type' => 'random' })

      assert_instance_of klass, rogue
      assert_equal 'flavour', rogue.notes
    end
  end

  test 'random generated results call the generator' do
    stub_generator('planetoid', PLANETOID_PAYLOAD)
    table = StubTable.new({ id: :planetoid, description: 'Rogue Dwarf Planet' })

    rogue = builder(rogue_table: table).build!(@parsec, { 'type' => 'random' })

    assert_instance_of Planetoid, rogue
    assert_equal 'Rogue Dwarf Planet', rogue.notes
  end

  test 'random gas giant rolls a size and calls the generator' do
    stub = stub_generator('gas_giant', GAS_GIANT_PAYLOAD, query: { 'size' => 'GM' })
    table = StubTable.new({ id: :gas_giant, description: 'Rogue Gas Giant' })

    rogue = builder(rogue_table: table, size_table: StubTable.new('GM')).build!(@parsec, { 'type' => 'random' })

    assert_requested stub
    assert_instance_of GasGiant, rogue
  end

  test 'historic habitation is usually a planetoid' do
    stub_generator('planetoid', PLANETOID_PAYLOAD)
    table = StubTable.new({ id: :historic_habitation, description: 'Signs of long-ago habitation' })

    rogue = builder(rogue_table: table, roller: StubRoller.new(1)).build!(@parsec, { 'type' => 'random' })

    assert_instance_of Planetoid, rogue
  end

  test 'historic habitation is sometimes a comet' do
    table = StubTable.new({ id: :historic_habitation, description: 'Signs of long-ago habitation' })

    rogue = builder(rogue_table: table, roller: StubRoller.new(4)).build!(@parsec, { 'type' => 'random' })

    assert_instance_of Comet, rogue
  end

  test 'generator failure raises a builder error' do
    stub_request(:get, "#{@base}/planetoid_belt").to_return(status: 500, body: 'boom')

    error = assert_raises(RogueObjectBuilder::Error) do
      builder.build!(@parsec, { 'type' => 'planetoid belt' })
    end

    assert_match(/planetoid belt/, error.message)
  end

  test 'unknown type raises a builder error' do
    assert_raises(RogueObjectBuilder::Error) do
      builder.build!(@parsec, { 'type' => 'dyson sphere' })
    end
  end
end
