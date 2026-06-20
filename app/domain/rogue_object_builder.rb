# frozen_string_literal: true

# Creates rogue stellar objects (parsec-bound, no orbiting star) from build
# configuration entries. The type vocabulary uses lowercase friendly names;
# size and comet variants are encoded in the type string, e.g. 'small gas
# giant' or 'inhabited comet'. The 'random' type rolls on the rogue objects
# table from the Worlds and Beyond Handbook.
class RogueObjectBuilder
  class Error < StandardError; end

  SIMPLE_TYPES = {
    'gas cloud'          => GasCloud,
    'gravity anomaly'    => GravityAnomaly,
    'interstellar wreck' => InterstellarWreck,
    'phantom object'     => PhantomObject,
    'radiation cloud'    => RadiationCloud,
    'relic'              => Relic,
    'space station'      => SpaceStation,
    'unusual object'     => UnusualObject
  }.freeze

  GENERATED_TYPES = {
    'planetoid'          => Planetoid,
    'planetoid belt'     => PlanetoidBelt,
    'terrestrial planet' => TerrestrialPlanet
  }.freeze

  GAS_GIANT_SIZES = { 'small' => 'GS', 'medium' => 'GM', 'large' => 'GL' }.freeze
  COMET_TYPES = Comet::DESCRIPTIONS.keys.freeze

  TYPES = (
    ['random'] +
    ['comet'] + COMET_TYPES.map { |t| "#{t} comet" } +
    ['gas giant'] + GAS_GIANT_SIZES.keys.map { |s| "#{s} gas giant" } +
    GENERATED_TYPES.keys +
    SIMPLE_TYPES.keys
  ).freeze

  def initialize(generator_service:, roller: DiceRoller.new,
                 rogue_table: RogueObjectsTable.new, size_table: GasGiantSizeTable.new)
    @generator_service = generator_service
    @roller = roller
    @rogue_table = rogue_table
    @size_table = size_table
  end

  def build!(parsec, entry)
    entry = entry.to_h.symbolize_keys
    type = entry[:type].to_s.downcase.squish

    rogue = instantiate(type)
    rogue.parsec = parsec
    rogue.name = entry[:name] if entry[:name].present?
    rogue.known = entry[:known] unless entry[:known].nil?
    rogue.save!
    rogue
  rescue ActiveRecord::RecordInvalid => e
    raise Error, "Could not create rogue '#{entry[:type]}': #{e.record.errors.full_messages.to_sentence}"
  end

  private

  def instantiate(type)
    return random_rogue if type == 'random'

    klass = SIMPLE_TYPES[type]
    return klass.new if klass

    klass = GENERATED_TYPES[type]
    return generated(klass) if klass

    return comet(comet_type_from(type)) if type.end_with?('comet')
    return gas_giant(size_from(type)) if type.end_with?('gas giant')

    raise Error, "Unknown rogue type '#{type}'"
  end

  def comet_type_from(type)
    return nil if type == 'comet'

    prefix = type.delete_suffix(' comet')
    COMET_TYPES.include?(prefix) ? prefix : raise(Error, "Unknown rogue type '#{type}'")
  end

  def size_from(type)
    return nil if type == 'gas giant'

    GAS_GIANT_SIZES.fetch(type.delete_suffix(' gas giant')) do
      raise Error, "Unknown rogue type '#{type}'"
    end
  end

  def comet(comet_type)
    comet_type ||= COMET_TYPES[@roller.roll(n: 1, d: COMET_TYPES.size, note: 'rogue comet type') - 1]
    Comet.new(comet_type: comet_type)
  end

  def gas_giant(size = nil)
    size ||= @size_table.roll(dm: 0, roller: @roller)
    generated(GasGiant, size: size)
  end

  def generated(klass, params = {})
    result = @generator_service.generate_stellar_object(klass, params: params)
    unless result.success?
      raise Error, "Could not generate rogue #{klass.model_name.human.downcase}: #{result.errors.to_sentence}"
    end

    klass.new.assign_data_from_generator(result.value)
  end

  def random_rogue
    result = @rogue_table.roll(dm: 0, roller: @roller)
    rogue = rogue_for_table_result(result)
    rogue.notes = result[:description]
    rogue
  end

  def rogue_for_table_result(result)
    case result[:id]
    when :sensor_glitch       then PhantomObject.new
    when :comet               then Comet.new(comet_type: result[:comet_type])
    when :unusual_object      then UnusualObject.new
    when :interstellar_wreck  then InterstellarWreck.new
    when :historic_habitation then historic_habitation
    when :gas_cloud           then GasCloud.new
    when :planetoid           then generated(Planetoid)
    when :planetoid_belt      then generated(PlanetoidBelt)
    when :terrestrial_planet  then generated(TerrestrialPlanet)
    when :gas_giant           then gas_giant
    else raise Error, "Unknown rogue table result '#{result[:id]}'"
    end
  end

  # WBH leaves the body type open; favour a planetoid three times in four.
  def historic_habitation
    if @roller.roll(n: 1, d: 4, note: 'historic habitation body type') == 4
      Comet.new
    else
      generated(Planetoid)
    end
  end
end
