# frozen_string_literal: true

# GurvinWordGenerator produces names in the style of the Hive Federation using a
# character-level, 2nd-order Markov chain trained on a ~4400-entry corpus of
# Hiver world names from sectors with HvFd, CsHv, and Hf allegiance codes.
#
# Two class constants are built at load time (once per process):
#   TABLE        — bigram → { next_char => count } transition table
#   CORPUS       — frozen Set of all downcased corpus entries (for deduplication)
#   WORD_COUNT_DIST — { word_count => frequency } observed in the corpus
#
class GurvinWordGenerator
  _entries = Rails.root.join('data', 'languages', 'gurvin.txt')
                  .readlines(chomp: true)
                  .map(&:strip)
                  .reject(&:empty?)

  CORPUS = Set.new(_entries.map(&:downcase)).freeze

  WORD_COUNT_DIST = _entries.each_with_object(Hash.new(0)) { |e, h| h[e.split.size] += 1 }.freeze

  TABLE = begin
    table = {}
    _entries.each do |entry|
      entry.split.each do |word|
        chars = ['^', '^'] + word.chars + ['$']
        chars.each_cons(3) do |a, b, c|
          key = a + b
          table[key] ||= {}
          table[key][c] = (table[key][c] || 0) + 1
        end
      end
    end
    table.transform_values(&:freeze).freeze
  end

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    20.times do
      count = pick_word_count
      name = Array.new(count) { generate_word }.join(' ')
      return name unless CORPUS.include?(name.downcase)
    end
    generate_word
  end

  private

  def generate_word
    10.times do
      state = '^^'
      chars = []
      14.times do
        transitions = TABLE[state]
        break unless transitions
        char = pick_from(transitions, 'Gurvin next char')
        break if char == '$'
        chars << char
        state = state[-1] + char
      end
      return chars.join.capitalize if chars.length >= 3
    end
    'Gurvin'
  end

  def pick_word_count
    total = WORD_COUNT_DIST.values.sum
    roll = @dice_roller.roll(n: 1, d: total, note: 'Gurvin word count')
    cumulative = 0
    WORD_COUNT_DIST.each do |count, weight|
      cumulative += weight
      return count if roll <= cumulative
    end
    1
  end

  def pick_from(transitions, note)
    total = transitions.values.sum
    roll = @dice_roller.roll(n: 1, d: total, note: note)
    cumulative = 0
    transitions.each do |char, weight|
      cumulative += weight
      return char if roll <= cumulative
    end
  end
end
