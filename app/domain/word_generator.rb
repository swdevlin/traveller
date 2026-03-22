# frozen_string_literal: true

# WordGenerator produces procedurally generated words in Traveller RPG alien languages.
# Instantiate with a language symbol; optionally inject a seeded DiceRoller for
# deterministic output in tests.
#
#   WordGenerator.new(language: :aslan).generate
#   WordGenerator.new(language: :aslan, dice_roller: DiceRoller.new(seed: 42)).generate
#
class WordGenerator
  def initialize(language:, dice_roller: nil)
    @language = language
    @dice_roller = dice_roller || DiceRoller.new
  end

  def generate
    generator.generate
  end

  def log
    @dice_roller.log
  end

  private

  def generator
    case @language
    when :aslan    then AslanWordGenerator.new(@dice_roller)
    when :french   then FrenchWordGenerator.new(@dice_roller)
    when :hindi    then HindiWordGenerator.new(@dice_roller)
    when :japanese then JapaneseWordGenerator.new(@dice_roller)
    when :korean   then KoreanWordGenerator.new(@dice_roller)
    when :nordic   then NordicWordGenerator.new(@dice_roller)
    when :oynprith  then OynprithWordGenerator.new(@dice_roller)
    when :solomani  then SolomaniWordGenerator.new(@dice_roller)
    when :arrghoun  then ArrghounWordGenerator.new(@dice_roller)
    when :gurvin    then GurvinWordGenerator.new(@dice_roller)
    when :zdetl     then ZdetlWordGenerator.new(@dice_roller)
    else raise ArgumentError, "Unknown language: #{@language}"
    end
  end
end
