# frozen_string_literal: true

# GurvinWordGenerator produces words in Gurvin — the K'kree language — using the
# K'KREE SOUND FREQUENCY TABLE from the Traveller RPG supplement (kkree.pdf, page 6).
#
# Phoneme frequencies are encoded directly from the table. Three special phonetic
# symbols appear in the vowel column:
#   '   glottal stop
#   !   clicking sound (tip of tongue against roof of mouth)
#   !!  complex double click (back of tongue against soft palate)
#   !'  click followed by glottal stop
#
# K'kree has four syllable types: V, CV, VC, CVC (ratio 1:6:2:4).
# Three syllable-type tables govern sequencing:
#   INITIAL  — first syllable; all four types permitted.
#   AFTER_V  — after a vowel-ending syllable (V or CV); only consonant-opening types
#              (CV, CVC) are permitted, preventing a vowel–vowel boundary.
#   AFTER_C  — after a consonant-ending syllable (VC); only vowel-opening types
#              (V, VC) are permitted, preventing a consonant–consonant boundary.
#
# CVC syllables automatically terminate the word regardless of target syllable count.
#
# Word length: 1D syllables per the rules. This implementation uses 1D3 (1–3 syllables)
# as a practical default that produces readable names.
#
class GurvinWordGenerator
  # Initial consonants — 23 sounds, total weight 98 (≈ 100 per table header).
  INITIAL_CONSONANTS = [
    ['k',   24],
    ['r',   12],
    ['kr',  10],
    ['t',    7],
    ['gh',   6],
    ['l',    5],
    ['gn',   4],
    ['n',    4],
    ['x',    4],
    ['g',    3],
    ['rr',   3],
    ['gr',   2],
    ['hk',   2],
    ['m',    2],
    ['tr',   2],
    ['b',    1],
    ['gz',   1],
    ['kt',   1],
    ['mb',   1],
    ['p',    1],
    ['xk',   1],
    ['xr',   1],
    ['xt',   1]
  ].freeze

  # Vowels — 14 sounds, total weight 60.
  # Includes glottal stop and click phonemes characteristic of Gurvin.
  VOWELS = [
    ['a',   19],
    ["'",    8],
    ['i',    6],
    ['u',    6],
    ['ee',   4],
    ['e',    3],
    ['!',    3],
    ['aa',   2],
    ['ii',   2],
    ['oo',   2],
    ['uu',   2],
    ['o',    1],
    ['!!',   1],
    ["!'",   1]
  ].freeze

  # Final consonants — 16 sounds, total weight 42.
  FINAL_CONSONANTS = [
    ['r',    8],
    ['k',    6],
    ['rr',   4],
    ['ng',   3],
    ['kr',   3],
    ['x',    3],
    ['t',    3],
    ['g',    2],
    ['n',    2],
    ['l',    2],
    ['b',    1],
    ['gh',   1],
    ['gr',   1],
    ['m',    1],
    ['p',    1],
    ['xk',   1]
  ].freeze

  # Initial syllable-type table — all four types permitted. Ratio V:CV:VC:CVC = 1:6:2:4.
  SYLLABLE_TYPES_INITIAL = [
    [:v,    1],
    [:cv,   6],
    [:vc,   2],
    [:cvc,  4]
  ].freeze

  # After-V table — used after a vowel-ending syllable (V or CV).
  # Only consonant-opening types permitted: CV and CVC. Proportions preserved from initial.
  SYLLABLE_TYPES_AFTER_V = [
    [:cv,   6],
    [:cvc,  4]
  ].freeze

  # After-C table — used after a consonant-ending syllable (VC).
  # Only vowel-opening types permitted: V and VC. Proportions preserved from initial.
  SYLLABLE_TYPES_AFTER_C = [
    [:v,    1],
    [:vc,   2]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    count = @dice_roller.roll(n: 1, d: 3, note: 'Gurvin syllable count')
    previous_type = nil
    syllables = []

    count.times do
      break if previous_type == :cvc

      table = case previous_type
      when nil  then SYLLABLE_TYPES_INITIAL
      when :v, :cv then SYLLABLE_TYPES_AFTER_V
      when :vc  then SYLLABLE_TYPES_AFTER_C
      end

      type = pick_from(table, 'Gurvin syllable type')
      syllables << build_syllable(type)
      previous_type = type
      break if type == :cvc
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
    pick_from(INITIAL_CONSONANTS, 'Gurvin initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Gurvin vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Gurvin final consonant')
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
