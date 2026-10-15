# frozen_string_literal: true

# WordGenerator produces procedurally generated words in Traveller RPG alien languages.
# Instantiate with a language symbol; optionally inject a seeded DiceRoller for
# deterministic output in tests.
#
#   WordGenerator.new(language: :aslan).generate
#   WordGenerator.new(language: :aslan, dice_roller: DiceRoller.new(seed: 42)).generate
#
class WordGenerator
  # Languages implemented in code, one *_word_generator.rb file each.
  BUILT_IN = Dir[Rails.root.join('app/domain/word_generators/*_word_generator.rb')]
             .map { |f| File.basename(f, '_word_generator.rb').to_sym }
             .reject { |lang| lang == :corpus }
             .sort
             .freeze

  # Built-in languages plus the current campaign's custom languages, sorted by display name.
  def self.languages
    custom = Language.pluck(:key, :name).to_h { |key, name| [key.to_sym, name] }
    labels = BUILT_IN.index_with { |lang| lang.to_s.capitalize }.merge(custom)
    labels.keys.sort_by { |lang| labels[lang].downcase }
  end

  def self.label(language)
    language = language.to_sym
    return language.to_s.capitalize if BUILT_IN.include?(language)

    Language.find_by(key: language.to_s)&.name || language.to_s.capitalize
  end

  def initialize(language:, dice_roller: nil)
    @language = language.to_sym
    @dice_roller = dice_roller || DiceRoller.new
  end

  def generate
    generator.generate.split.map(&:capitalize).join(' ')
  end

  def log
    @dice_roller.log
  end

  private

  def generator
    @generator ||= build_generator
  end

  def build_generator
    return "#{@language.to_s.camelize}WordGenerator".constantize.new(@dice_roller) if BUILT_IN.include?(@language)

    custom = Language.find_by(key: @language.to_s)
    raise ArgumentError, "Unknown language: #{@language}" unless custom

    CorpusWordGenerator.for(custom, @dice_roller)
  end
end
