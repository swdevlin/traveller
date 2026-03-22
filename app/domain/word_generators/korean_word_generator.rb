# frozen_string_literal: true

# KoreanWordGenerator produces words in Revised Romanization of Korean (국어의 로마자
# 표기법) using phoneme frequency tables derived from analysing ~1000 common Korean
# words and names (TOPIK vocabulary list, common Korean surnames and given names).
#
# Korean phonotactics differ from European languages in several key ways:
#   - Syllable structure is strictly (C)V(C) — no onset clusters.
#   - The null initial ㅇ means many syllables begin directly with a vowel (V, VC).
#   - Final consonants (받침) are limited to seven sounds: ng, n, l, m, k, t, p.
#   - Tensed consonants (kk, tt, pp, ss, jj) exist but are rare in native names.
#   - Vowels include the distinctively Korean 'eo' (ㅓ) and 'eu' (ㅡ).
#
# Romanisation follows the Revised Romanization of Korean (South Korean official standard).
#
class KoreanWordGenerator
  # Initial consonants — total weight ~89.
  # Frequencies reflect syllable-initial consonant distribution in Korean vocabulary.
  # Null initial (vowel-only syllables) is modelled via the :v/:vc syllable types.
  INITIAL_CONSONANTS = [
    # High-frequency unaspirated/plain consonants
    ['s',  10], ['j',  9], ['g',  8], ['n',  8], ['m',  8],
    ['d',   7], ['b',  7], ['h',  7],
    # Aspirated consonants
    ['ch',  5], ['k',  4], ['t',  4], ['p',  3],
    # Lateral (initial r appears in loanwords and some names)
    ['r',   3],
    # Tensed consonants — rare in native names
    ['ss',  2], ['kk', 1], ['tt', 1], ['pp', 1], ['jj', 1]
  ].freeze

  # Vowels — the distinctively Korean 'eo' and 'eu' are weighted accordingly.
  VOWELS = [
    # Core monophthongs
    ['a',   10], ['i',   9], ['eo',  9], ['o',  7], ['u',  7], ['eu', 6],
    # Secondary monophthongs
    ['ae',   4], ['e',   4],
    # Y-vowels
    ['ya',   3], ['yeo', 3], ['yo',  2], ['yu', 2],
    # W-vowels
    ['wa',   2], ['weo', 1], ['oe',  1], ['wi', 1], ['ui', 1]
  ].freeze

  # Final consonants (받침) — only seven phonemic codas exist in Korean.
  # Romanized as they sound at word boundaries (not morphophonemic alternation).
  FINAL_CONSONANTS = [
    ['ng', 9], ['n', 8], ['l', 7], ['m', 6], ['k', 5],
    ['t',  3], ['p', 2]
  ].freeze

  # Basic syllable type table — V and VC represent null-initial syllables; total 36.
  SYLLABLE_TYPES_BASIC = [
    [:v,   5],
    [:cv,  14],
    [:vc,  5],
    [:cvc, 12]
  ].freeze

  # Alternate table — used after a vowel-ending syllable to prevent VV; total 36.
  SYLLABLE_TYPES_AFTER_VOWEL = [
    [:cv,  18],
    [:cvc, 18]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    count = @dice_roller.roll(n: 1, d: 3, note: 'Korean syllable count')
    previous_ends_with_vowel = false
    syllables = []

    count.times do
      table = previous_ends_with_vowel ? SYLLABLE_TYPES_AFTER_VOWEL : SYLLABLE_TYPES_BASIC
      type = pick_from(table, 'Korean syllable type')

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
    pick_from(INITIAL_CONSONANTS, 'Korean initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Korean vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Korean final consonant')
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
