# frozen_string_literal: true

# HindiWordGenerator produces words in simplified ASCII transliteration of Hindi
# (Devanagari) using phoneme frequency tables derived from analysing ~1000 common
# Hindi words and names (NCERT basic vocabulary, common Hindi given names, and
# Sanskrit-derived words from everyday use).
#
# Transliteration conventions (simplified IAST, ASCII-only):
#   - Long vowels: aa (आ), ii (ई), uu (ऊ)
#   - Aspirated stops: kh, gh, ch, jh, th, dh, ph, bh
#   - Retroflex stops (ट ड) are merged with dental t/d for readability
#   - Palatal sibilant (श) and retroflex sibilant (ष) → sh
#   - The inherent vowel 'a' is written explicitly
#
# Hindi has a high proportion of open (CV) syllables due to the inherent 'a' vowel
# in Devanagari script, and rich onset clusters from its Sanskrit heritage.
#
class HindiWordGenerator
  # Initial consonants and clusters — total weight ~140.
  INITIAL_CONSONANTS = [
    # High-frequency plain consonants
    ['s',   9], ['r',  9], ['p',  8], ['m',  8], ['t',  8],
    ['k',   7], ['n',  7], ['v',  6], ['d',  6], ['h',  5],
    ['j',   5], ['b',  5], ['l',  4], ['g',  4], ['y',  4],
    # Palatal affricate
    ['ch',  5],
    # Aspirated consonants — frequent in Hindi/Sanskrit vocabulary
    ['kh',  3], ['th',  3], ['dh',  3], ['bh',  3],
    ['gh',  2], ['ph',  2], ['jh',  1],
    # Palatal/retroflex sibilant
    ['sh',  4],
    # Onset clusters — Sanskrit-derived words use these heavily
    ['pr',  4], ['br',  3], ['kr',  3], ['tr',  3],
    ['gr',  2], ['dr',  2], ['shr', 2], ['str', 1]
  ].freeze

  # Vowels — 'a' dominates due to the inherent schwa vowel of Devanagari.
  VOWELS = [
    # Short vowels
    ['a',  12], ['i',  8], ['u',  7],
    # Long vowels
    ['aa',  8], ['ii',  5], ['uu',  4],
    # Other vowels
    ['e',   5], ['o',   5],
    # Diphthongs
    ['ai',  3], ['au',  3]
  ].freeze

  # Final consonants — Hindi words commonly end in vowels, but when a consonant
  # closes the syllable, nasals and liquids are most frequent.
  FINAL_CONSONANTS = [
    # Nasals and liquids (most common codas)
    ['n',  9], ['m',  7], ['r',  6], ['l',  5],
    # Stop consonants
    ['t',  5], ['k',  4], ['d',  4], ['s',  3],
    # Nasal coda digraph
    ['ng', 3],
    # Aspirated codas (rare)
    ['th', 2], ['dh', 2],
    # Coda clusters
    ['nd', 3], ['nt', 3], ['rt', 2], ['rd', 2], ['mp', 2], ['nk', 2]
  ].freeze

  # Basic syllable type table — CV dominates in Hindi due to the inherent vowel;
  # total weight 36.
  SYLLABLE_TYPES_BASIC = [
    [:v,   3],
    [:cv,  18],
    [:vc,  5],
    [:cvc, 10]
  ].freeze

  # Alternate table — used after a vowel-ending syllable to prevent VV; total 36.
  SYLLABLE_TYPES_AFTER_VOWEL = [
    [:cv,  22],
    [:cvc, 14]
  ].freeze

  def initialize(dice_roller)
    @dice_roller = dice_roller
  end

  def generate
    count = @dice_roller.roll(n: 1, d: 3, note: 'Hindi syllable count')
    previous_ends_with_vowel = false
    syllables = []

    count.times do
      table = previous_ends_with_vowel ? SYLLABLE_TYPES_AFTER_VOWEL : SYLLABLE_TYPES_BASIC
      type = pick_from(table, 'Hindi syllable type')

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
    pick_from(INITIAL_CONSONANTS, 'Hindi initial consonant')
  end

  def vowel
    pick_from(VOWELS, 'Hindi vowel')
  end

  def final_consonant
    pick_from(FINAL_CONSONANTS, 'Hindi final consonant')
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
