# frozen_string_literal: true

# AslanWordGenerator produces words using the Aslan Sound Frequency Table from the
# Traveller RPG rulebook. Tables are encoded as weighted arrays; pick_from rolls
# 1D(total_weight) and selects by cumulative frequency.
#
# Frequency tables are read from the ASLAN SOUND FREQUENCY TABLE scan (aslan.jpg).
# Weights are calibrated so that:
#   - roll 3 on the initial consonant table → kh  (Word Generation Example, p.1)
#   - roll 7 on the vowel table             → ao  (Word Generation Example, p.1)
#   - roll 7 on the basic syllable table    → CV  (Word Generation Example, p.1)
#
class AslanWordGenerator
  # Initial consonants — total weight 36 (2D6-equivalent distribution).
  # Order establishes cumulative positions: ft=1, hl=2, kh=3-5 → roll 3 picks kh.
  INITIAL_CONSONANTS = [
    ['ft', 1], ['hl', 1], ['kh', 3], ['hw', 2],
    ['l', 5], ['r', 6], ['s', 5], ['t', 4],
    ['tl', 3], ['tr', 2], ['w', 2], ['y', 2]
  ].freeze

  # Vowels (singles and diphthongs) — total weight 36.
  # a occupies cumulative 1-6, ao starts at 7 → roll 7 picks ao.
  VOWELS = [
    ['a', 6], ['ao', 5], ['e', 5], ['i', 4],
    ['o', 4], ['u', 3], ['ea', 5], ['ia', 4]
  ].freeze

  # Final consonants share the same distribution as initial consonants.
  FINAL_CONSONANTS = INITIAL_CONSONANTS

  # Basic syllable type table (2D6-equivalent, total 36).
  # CV occupies cumulative 4-15 → roll 7 picks CV.
  SYLLABLE_TYPES_BASIC = [
    [:v, 3], [:cv, 12], [:vc, 9], [:cvc, 12]
  ].freeze

  # Alternate syllable type table — used when the previous syllable ended with a
  # vowel, preventing a VV boundary. Only consonant-initial types are possible.
  # CVC is weighted more heavily than CV (total 36).
  SYLLABLE_TYPES_ALTERNATE = [
    [:cv, 12], [:cvc, 24]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    count = @dice_roller.roll(n: 1, d: 3, note: 'Aslan syllable count')
    previous_ends_with_vowel = false
    syllables = []

    count.times do
      table = previous_ends_with_vowel ? SYLLABLE_TYPES_ALTERNATE : SYLLABLE_TYPES_BASIC
      type = pick_from(table, 'Aslan syllable type')

      syllables << build_syllable(type)
      previous_ends_with_vowel = type == :v || type == :cv
    end

    syllables.join
  end

  private

  def build_syllable(type)
    case type
    when :v   then vowel
    when :cv  then consonant + vowel
    when :vc  then vowel + final_consonant
    when :cvc then consonant + vowel + final_consonant
    end
  end

  def consonant
    pick_from(INITIAL_CONSONANTS, 'Aslan initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Aslan vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Aslan final consonant')
  end

  def pick_from(table, note)
    total = table.sum { |_, weight| weight }
    roll = @dice_roller.roll(n: 1, d: total, note: note)
    cumulative = 0
    table.each do |sound, weight|
      cumulative += weight
      return sound if roll <= cumulative
    end
  end
end
